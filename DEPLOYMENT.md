# Deployment Guide (Linux / Ubuntu)

This document explains how to deploy the Django + nginx-rtmp streaming server in production.

## 1) Prerequisites
- Ubuntu 22.04+ (root/sudo access)
- Python 3.10+ and `venv`
- git
- Ports open: 80/443 (web), 1935 (RTMP), 8000 (app, or behind reverse proxy), 9000 (HLS, or proxied)

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

## 4) Build nginx with RTMP
Install dependencies and build (one-time):
```bash
sudo bash setup_nginx_rtmp.sh
```
If you already have nginx, ensure the RTMP build is installed at `/usr/local/nginx/sbin/nginx`.

Copy our RTMP + HLS config:
```bash
sudo cp nginx/nginx.conf /usr/local/nginx/conf/nginx.conf
```

## 5) Start services (manual run)
In two terminals (or use systemd below):
```bash
# Terminal 1: nginx RTMP + HLS
sudo /usr/local/nginx/sbin/nginx

# Terminal 2: Django app (gunicorn recommended in prod)
source .venv/bin/activate
python manage.py runserver 0.0.0.0:8000
```

## 6) Recommended: Gunicorn + systemd for Django
Install gunicorn:
```bash
pip install gunicorn
```

Create systemd service `/etc/systemd/system/streaming_server.service`:
```
[Unit]
Description=Gunicorn for streaming_server
After=network.target

[Service]
User=www-data
Group=www-data
WorkingDirectory=/opt/streaming_server/streaming_server
Environment="PATH=/opt/streaming_server/streaming_server/.venv/bin"
ExecStart=/opt/streaming_server/streaming_server/.venv/bin/gunicorn streaming_server.wsgi:application \
  --bind 0.0.0.0:8000 --workers 3
Restart=always

[Install]
WantedBy=multi-user.target
```
Then enable:
```bash
sudo systemctl daemon-reload
sudo systemctl enable --now streaming_server
```

## 7) nginx as reverse proxy (optional but recommended)
If you want to serve Django via nginx (port 80/443) instead of 8000, add a server block in `/usr/local/nginx/conf/nginx.conf` http section:
```
server {
    listen 80;
    server_name your.domain;

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # HLS passthrough (optional if you proxy 9000)
    location /live/ {
        proxy_pass http://127.0.0.1:9000;
    }
}
```
Reload nginx:
```bash
sudo /usr/local/nginx/sbin/nginx -s reload
```

## 8) Firewalls
```bash
sudo ufw allow 80
sudo ufw allow 443
sudo ufw allow 1935
sudo ufw allow 8000   # if directly exposed
sudo ufw allow 9000   # if directly exposed
```

## 9) Verify
- RTMP ingest (OBS): `rtmp://your.server.ip:1935/live/{STREAM_KEY}`
- HLS playlist: `http://your.server.ip:9000/live/{STREAM_KEY}.m3u8`
- Watch page: `http://your.server.ip:8000/watch/{STREAM_KEY}/` (or your domain)
- nginx config test: `sudo /usr/local/nginx/sbin/nginx -t`

## 10) Logs
- nginx: `/usr/local/nginx/logs/error.log`
- gunicorn: `journalctl -u streaming_server -f`
- Django (runserver): shown in terminal

## 11) Updating the app
```bash
cd /opt/streaming_server/streaming_server
source .venv/bin/activate
git pull
pip install -r requirements.txt  # if changed
python manage.py migrate
python manage.py collectstatic --noinput
sudo systemctl restart streaming_server
sudo /usr/local/nginx/sbin/nginx -s reload
```

## 12) SSL (Let's Encrypt quick note)
For a domain, use a public nginx (port 80/443) and obtain certificates:
```bash
sudo apt install certbot
sudo certbot certonly --standalone -d your.domain
```
Then configure TLS in the nginx server block (443) with the issued `fullchain.pem` and `privkey.pem`.

---

Your streaming stack is production-ready once nginx-rtmp is running, gunicorn serves Django, and firewall rules are in place.
