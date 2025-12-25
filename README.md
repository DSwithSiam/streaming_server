# OBS Streaming Server

A Django-based streaming server that receives RTMP streams from OBS and serves them as HLS for web playback.

## Features
- 🎥 RTMP streaming from OBS
- 📺 HLS playback in web browsers
- 🔑 Unique stream keys for each broadcast
- 📊 Live stream status tracking
- 🌐 Low latency streaming

## Installation

### 1. Install nginx with RTMP module

```bash
sudo bash setup_nginx_rtmp.sh
```

This will:
- Install dependencies
- Download and compile nginx with RTMP module
- Set up HLS directory
- Configure nginx

### 2. Set up Django

```bash
# Create and activate virtual environment (recommended)
python -m venv venv
source venv/bin/activate  # On Linux/Mac
# or
venv\Scripts\activate  # On Windows

# Install Django
pip install django

# Run migrations
python manage.py makemigrations
python manage.py migrate

# Create superuser (optional)
python manage.py createsuperuser
```

## Usage

### Start the Server

**Option 1: Quick Start (both nginx and Django)**
```bash
bash start_server.sh
```

**Option 2: Manual Start**
```bash
# Terminal 1: Start nginx
sudo /usr/local/nginx/sbin/nginx

# Terminal 2: Start Django
python manage.py runserver 0.0.0.0:8000
```

### Create a Stream Key

```bash
# Visit in browser or use curl
curl http://localhost:8000/create_stream_key/?title=My%20Stream
```

Response:
```json
{
  "stream_key": "abc123def456...",
  "title": "My Stream",
  "rtmp_url": "rtmp://localhost/live/abc123def456...",
  "watch_url": "/watch/abc123def456.../"
}
```

### Configure OBS

1. Open OBS Studio
2. Go to **Settings → Stream**
3. Select **Custom** as Service
4. Enter Server: `rtmp://YOUR_SERVER_IP/live`
5. Enter Stream Key: `YOUR_STREAM_KEY` (from create_stream_key)
6. Click **OK**
7. Click **Start Streaming**

### Watch the Stream

Open in browser:
```
http://YOUR_SERVER_IP:8000/watch/YOUR_STREAM_KEY/
```

### List All Streams

```bash
curl http://localhost:8000/list_streams/
```

## API Endpoints

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/create_stream_key/?title=xxx` | GET | Create new stream key |
| `/list_streams/` | GET | List all streams |
| `/watch/<stream_key>/` | GET | Watch stream in browser |
| `/on_publish/` | POST | Webhook for stream start (internal) |
| `/on_publish_done/` | POST | Webhook for stream end (internal) |

## Configuration

### nginx RTMP Settings
Edit `nginx/nginx.conf`:
- RTMP Port: `1935` (default)
- HLS Fragment: `3 seconds`
- HLS Playlist: `60 seconds`

### Django Settings
Edit `streaming_server/settings.py`:
- Add your server IP/domain to `ALLOWED_HOSTS`
- Update `CSRF_TRUSTED_ORIGINS` for production

## Troubleshooting

### Check nginx status
```bash
sudo /usr/local/nginx/sbin/nginx -t  # Test config
ps aux | grep nginx                   # Check if running
```

### Check nginx logs
```bash
sudo tail -f /usr/local/nginx/logs/error.log
```

### Check HLS files
```bash
ls -la /tmp/hls/
```

### Restart nginx
```bash
sudo /usr/local/nginx/sbin/nginx -s stop
sudo /usr/local/nginx/sbin/nginx
```

### Port 1935 in use
```bash
sudo lsof -i :1935
sudo kill -9 <PID>
```

## Stop Server

```bash
bash stop_server.sh
# or manually:
sudo /usr/local/nginx/sbin/nginx -s stop
# Press Ctrl+C in Django terminal
```

## Production Deployment

1. Set `DEBUG = False` in settings.py
2. Configure proper `ALLOWED_HOSTS`
3. Use a production WSGI server (gunicorn, uwsgi)
4. Set up SSL/TLS certificates
5. Configure firewall (ports 1935, 80, 443)
6. Use systemd services for auto-restart

## Tech Stack
- Django 6.0
- nginx with nginx-rtmp-module
- HLS (HTTP Live Streaming)
- JavaScript HLS.js player

## License
MIT
