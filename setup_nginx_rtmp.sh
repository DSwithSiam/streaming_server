#!/bin/bash

echo "=========================================="
echo "OBS Streaming Server Setup"
echo "=========================================="

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root (use sudo)"
    exit 1
fi

echo "[1/6] Installing dependencies..."
apt-get update
apt-get install -y build-essential libpcre3 libpcre3-dev libssl-dev zlib1g-dev

echo "[2/6] Downloading nginx and nginx-rtmp-module..."
cd /tmp
wget http://nginx.org/download/nginx-1.24.0.tar.gz
wget https://github.com/arut/nginx-rtmp-module/archive/master.zip -O nginx-rtmp-module.zip

echo "[3/6] Extracting archives..."
tar -zxvf nginx-1.24.0.tar.gz
apt-get install -y unzip
unzip nginx-rtmp-module.zip

echo "[4/6] Compiling nginx with RTMP module..."
cd nginx-1.24.0
./configure --with-http_ssl_module --add-module=../nginx-rtmp-module-master
make
make install

echo "[5/6] Creating HLS directory..."
mkdir -p /tmp/hls
chmod -R 755 /tmp/hls

echo "[6/6] Copying nginx configuration..."
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cp "$SCRIPT_DIR/nginx/nginx.conf" /usr/local/nginx/conf/nginx.conf

echo "=========================================="
echo "Installation Complete!"
echo "=========================================="
echo ""
echo "To start the streaming server:"
echo "  1. Start nginx: sudo /usr/local/nginx/sbin/nginx"
echo "  2. Start Django: python manage.py runserver 0.0.0.0:8000"
echo ""
echo "To stop nginx:"
echo "  sudo /usr/local/nginx/sbin/nginx -s stop"
echo ""
echo "To reload nginx config:"
echo "  sudo /usr/local/nginx/sbin/nginx -s reload"
echo ""
echo "RTMP URL for OBS: rtmp://YOUR_SERVER_IP/live/YOUR_STREAM_KEY"
echo "Watch URL: http://YOUR_SERVER_IP:8000/watch/YOUR_STREAM_KEY/"
echo "=========================================="
