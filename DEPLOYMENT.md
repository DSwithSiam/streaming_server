# Deployment Guide (Linux / Ubuntu)

This document explains how to deploy the Django + nginx-rtmp streaming server in production.

## Architecture Overview

```
                    Internet
                        ↓
            System nginx (Port 80/443)
            /etc/nginx/ - Reverse Proxy
                    ↓
         ┌──────────┴──────────┐
         ↓                     ↓
   Django (8000)      Custom nginx (9000)
   Web API/Pages      HLS Streaming
         ↑                     ↑
         └─────────────────────┘
           Custom nginx (1935)
           /usr/local/nginx/ - RTMP Server
```

**Two nginx instances:**
1. **System nginx** (`/etc/nginx/`) - Reverse proxy on port 80/443
2. **Custom nginx** (`/usr/local/nginx/`) - RTMP (1935) + HLS (9000)

## 1) Prerequisites
- Ubuntu 22.04+ (root/sudo access)
- Python 3.10+ and `venv`
- git
- Ports open: 80/443 (web), 1935 (RTMP)

## 2) Clone and set up Python env
```bash
cd /opt
sudo git clone https://github.com/DSwithSiam/streaming_server.git
sudo chown -R $USER:$USER streaming_server
cd streaming_server/streaming_server
python -m venv .venv
source .venv/bin/activate
pip install --upgrade pip
pip install -r requirements.txt  # if present; otherwise pip install django
```

## 3) Django configuration
Edit `streaming_server/settings.py`:
- `DEBUG = False`
- `ALLOWED_HOSTS = ['your.domain', 'your.server.ip']`
- `CSRF_TRUSTED_ORIGINS = ['https://your.domain']`
- Set a strong `SECRET_KEY`

Run migrations and create a superuser (optional):
```bash
python manage.py migrate
python manage.py createsuperuser  # optional
```

Collect static files (if you add static assets):
```bash
python manage.py collectstatic --noinput
```

## 4) Build Custom nginx with RTMP Module
Install dependencies and build (one-time):
```bash
sudo bash setup_nginx_rtmp.sh
```
This creates `/usr/local/nginx/` with RTMP module support.

Copy RTMP + HLS config:
```bash
sudo cp nginx/nginx.conf /usr/local/nginx/conf/nginx.conf
sudo /usr/local/nginx/sbin/nginx -t  # Test config
```

## 5) Setup System nginx as Reverse Proxy
Create reverse proxy config:
```bash
sudo tee /etc/nginx/sites-available/streaming << 'EOF'
server {
    listen 80;
    server_name 10.10.13.73;  # Change to your domain or IP

    # Django proxy
    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # HLS streaming proxy
    location /live/ {
        proxy_pass http://127.0.0.1:9000/live/;
        add_header Cache-Control no-cache;
        add_header Access-Control-Allow-Origin *;
    }
}
EOF
```

Enable the config:
```bash
sudo ln -s /etc/nginx/sites-available/streaming /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/default  # Remove default site
sudo nginx -t  # Test system nginx config
```

## 6) Start All Services

### Option 1: Quick Start (Development)
```bash
# Start custom nginx (RTMP + HLS)
sudo /usr/local/nginx/sbin/nginx

# Start system nginx (reverse proxy)
sudo systemctl start nginx
sudo systemctl enable nginx

# Start Django (in another terminal)
source .venv/bin/activate
python manage.py runserver 0.0.0.0:8000
```

### Option 2: Use start_server.sh Script
```bash
bash start_server.sh
# Then manually start system nginx:
sudo systemctl start nginx
```

## 7) Production: Gunicorn + systemd for Django
Install gunicorn:
```bash
pip install gunicorn
```

Create systemd service `/etc/systemd/system/streaming_server.service`:
```ini
[Unit]
Description=Gunicorn for streaming_server
After=network.target

[Service]
User=backend
Group=backend
WorkingDirectory=/home/backend/siam/streaming_server/streaming_server
Environment="PATH=/home/backend/siam/streaming_server/streaming_server/.venv/bin"
ExecStart=/home/backend/siam/streaming_server/streaming_server/.venv/bin/gunicorn streaming_server.wsgi:application \
  --bind 127.0.0.1:8000 --workers 3
Restart=always

[Install]
WantedBy=multi-user.target
```

Enable and start:
```bash
sudo systemctl daemon-reload
sudo systemctl enable streaming_server
sudo systemctl start streaming_server
sudo systemctl status streaming_server
```

## 8) Create systemd service for Custom nginx (Optional)
Create `/etc/systemd/system/nginx-rtmp.service`:
```ini
[Unit]
Description=nginx RTMP Server
After=network.target

[Service]
Type=forking
PIDFile=/usr/local/nginx/logs/nginx.pid
ExecStartPre=/usr/local/nginx/sbin/nginx -t
ExecStart=/usr/local/nginx/sbin/nginx
ExecReload=/usr/local/nginx/sbin/nginx -s reload
ExecStop=/usr/local/nginx/sbin/nginx -s quit
Restart=always

[Install]
WantedBy=multi-user.target
```

Enable:
```bash
sudo systemctl daemon-reload
sudo systemctl enable nginx-rtmp
sudo systemctl start nginx-rtmp
```

## 9) Firewall Configuration
```bash
sudo ufw allow 80/tcp      # HTTP (system nginx)
sudo ufw allow 443/tcp     # HTTPS (for SSL)
sudo ufw allow 1935/tcp    # RTMP (for OBS)
sudo ufw enable
```

**Note**: Ports 8000 and 9000 are NOT exposed - they're internal only!

## 10) Verify Deployment
After all services are running, verify:

```bash
# Check services
sudo systemctl status nginx              # System nginx
sudo systemctl status nginx-rtmp         # Custom nginx (if using systemd)
sudo systemctl status streaming_server   # Django/Gunicorn
ps aux | grep nginx                      # Should see both nginx instances

# Check ports
sudo lsof -i :80    # System nginx
sudo lsof -i :1935  # RTMP
sudo lsof -i :8000  # Django
sudo lsof -i :9000  # HLS

# Test endpoints
curl http://localhost/                           # Django home (via proxy)
curl http://localhost/list_streams/              # API (via proxy)
curl -I http://localhost:9000/live/test.m3u8    # Direct HLS (internal)
```

**Public URLs** (accessible from outside):
- **Web UI**: `http://10.10.13.73/` (or your domain)
- **HLS Streams**: `http://10.10.13.73/live/{STREAM_KEY}.m3u8`
- **RTMP Ingest**: `rtmp://10.10.13.73:1935/live/{STREAM_KEY}`

## 11) Configure OBS Studio
1. Open OBS → Settings → Stream
2. Service: **Custom**
3. Server: `rtmp://10.10.13.73:1935/live`
4. Stream Key: Get from `http://10.10.13.73/create_stream_key/?title=MyStream`
5. Click **OK** → **Start Streaming**

## 12) Logs & Troubleshooting

### View Logs
```bash
# System nginx
sudo tail -f /var/log/nginx/error.log
sudo tail -f /var/log/nginx/access.log

# Custom nginx (RTMP/HLS)
sudo tail -f /usr/local/nginx/logs/error.log
sudo tail -f /usr/local/nginx/logs/access.log

# Django/Gunicorn
sudo journalctl -u streaming_server -f

# Check HLS files being created
ls -la /tmp/hls/
watch -n 1 'ls -lh /tmp/hls/'  # Live monitoring
```

### Common Issues

**System nginx won't start:**
```bash
sudo nginx -t  # Check config syntax
sudo systemctl status nginx
```

**Custom nginx won't start:**
```bash
sudo /usr/local/nginx/sbin/nginx -t
ps aux | grep nginx
sudo pkill -f '/usr/local/nginx'  # Kill old processes
sudo /usr/local/nginx/sbin/nginx  # Restart
```

**No HLS files created:**
- Ensure OBS is connected and streaming
- Check RTMP connection in OBS (should show "Connected")
- Verify `/tmp/hls/` directory exists and is writable
- Check custom nginx error log

**Can't access from browser:**
- Check firewall: `sudo ufw status`
- Verify system nginx is running: `sudo systemctl status nginx`
- Test locally first: `curl http://localhost/`

## 13) Updating the Application
```bash
cd /home/backend/siam/streaming_server/streaming_server
source .venv/bin/activate
git pull
pip install -r requirements.txt  # if changed
python manage.py migrate
python manage.py collectstatic --noinput

# Restart services
sudo systemctl restart streaming_server
sudo systemctl restart nginx
sudo /usr/local/nginx/sbin/nginx -s reload
```

## 14) SSL/HTTPS Setup (Let's Encrypt)
For production with a domain name:

```bash
# Install certbot
sudo apt install certbot python3-certbot-nginx

# Get certificate (system nginx must be running on port 80)
sudo certbot --nginx -d your.domain.com

# Certbot will automatically update /etc/nginx/sites-available/streaming
# to add SSL configuration

# Auto-renewal (certbot sets this up automatically)
sudo systemctl status certbot.timer
```

Update system nginx config to redirect HTTP to HTTPS:
```bash
sudo nano /etc/nginx/sites-available/streaming
```

Example SSL config:
```nginx
server {
    listen 80;
    server_name your.domain.com;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name your.domain.com;

    ssl_certificate /etc/letsencrypt/live/your.domain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/your.domain.com/privkey.pem;

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    location /live/ {
        proxy_pass http://127.0.0.1:9000/live/;
        add_header Cache-Control no-cache;
        add_header Access-Control-Allow-Origin *;
    }
}
```

Then reload:
```bash
sudo nginx -t
sudo systemctl reload nginx
```

## 15) Performance Tuning

### For High Traffic

**Custom nginx (RTMP/HLS):**
Edit `/usr/local/nginx/conf/nginx.conf`:
```nginx
worker_processes auto;
worker_rlimit_nofile 100000;

events {
    worker_connections 4096;
    use epoll;
}
```

**Gunicorn workers:**
Edit systemd service or use:
```bash
gunicorn --workers $((2 * $(nproc) + 1)) --bind 127.0.0.1:8000
```

**System nginx:**
Edit `/etc/nginx/nginx.conf`:
```nginx
worker_processes auto;
events {
    worker_connections 2048;
}
```

---

## Summary

Your production stack:
- ✅ **System nginx** (port 80/443) - Public facing reverse proxy
- ✅ **Custom nginx** (port 1935, 9000) - RTMP ingest + HLS generation
- ✅ **Django/Gunicorn** (port 8000) - Internal API and web interface
- ✅ All managed by systemd with auto-restart
- ✅ Firewall configured (only 80, 443, 1935 exposed)
- ✅ SSL ready with Let's Encrypt

The streaming server is now production-ready! 🎥🚀
