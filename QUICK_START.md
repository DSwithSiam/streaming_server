# Quick Start Guide - OBS Streaming Server

## Server Information
- **Server IP**: 10.10.13.73
- **Date Updated**: December 25, 2025

## Ports & Services
| Service | Port | URL |
|---------|------|-----|
| RTMP (OBS Ingest) | 1935 | `rtmp://10.10.13.73:1935/live/` |
| Django Web App | 8000 | `http://10.10.13.73:8000/` |
| HLS Streaming | 9000 | `http://10.10.13.73:9000/live/` |

## Quick Commands

### 1. Start Server
```bash
cd /home/backend/siam/streaming_server/streaming_server
bash start_server.sh
```

This will:
- Stop system nginx (apt version)
- Kill any existing custom nginx processes
- Copy updated nginx config
- Start custom nginx on ports 1935 (RTMP) + 9000 (HLS)
- Start Django on port 8000

### 2. Create Stream Key
```bash
curl "http://10.10.13.73:8000/create_stream_key/?title=MyStream"
```

Response example:
```json
{
  "stream_key": "abc123def456xyz",
  "title": "MyStream",
  "rtmp_url": "rtmp://10.10.13.73:1935/live/abc123def456xyz",
  "watch_url": "http://10.10.13.73:8000/watch/abc123def456xyz/",
  "hls_url": "http://10.10.13.73:9000/live/abc123def456xyz.m3u8"
}
```

### 3. Configure OBS
1. Open OBS Studio
2. Go to **Settings → Stream**
3. Select **Custom** Service
4. **Server**: `rtmp://10.10.13.73:1935/live`
5. **Stream Key**: `abc123def456xyz` (from step 2)
6. Click **OK** and **Start Streaming**

### 4. Watch Stream
Browser: `http://10.10.13.73:8000/watch/abc123def456xyz/`

Or use VLC: `http://10.10.13.73:9000/live/abc123def456xyz.m3u8`

### 5. Stop Server
```bash
bash stop_server.sh
```

## Useful Commands

### Check Service Status
```bash
ps aux | grep '/usr/local/nginx'  # nginx
ps aux | grep 'manage.py'          # Django
```

### Check Port Usage
```bash
lsof -i :1935   # RTMP
lsof -i :8000   # Django
lsof -i :9000   # HLS
```

### Tail nginx Errors
```bash
sudo tail -f /usr/local/nginx/logs/error.log
```

### Check HLS Files
```bash
ls -la /tmp/hls/
```

### List All Streams
```bash
curl http://10.10.13.73:8000/list_streams/
```

## Troubleshooting

### nginx won't start
```bash
# Check if system nginx is running
sudo systemctl stop nginx
sudo systemctl disable nginx

# Kill any leftover processes
sudo pkill -f nginx
sleep 2

# Try again
bash start_server.sh
```

### Port already in use
```bash
# Find what's using port 9000
sudo lsof -i :9000

# Kill it
sudo kill -9 <PID>
```

### No HLS files in /tmp/hls/
- Ensure OBS is streaming (you should see "Live" in the app)
- Check nginx error log: `sudo tail -f /usr/local/nginx/logs/error.log`
- Verify RTMP connection in OBS (should show "Connected")

## Documentation
- `README.md` - Full feature overview
- `DEPLOYMENT.md` - Production deployment guide
- `BANGLA_GUIDE.md` - Bengali language guide

## Next Steps
1. Run `bash start_server.sh`
2. Create a stream key via API
3. Configure OBS with RTMP URL and stream key
4. Start streaming from OBS
5. Watch in browser
