#!/bin/bash

echo "Starting OBS Streaming Server..."

# Check if nginx is installed
if [ ! -f /usr/local/nginx/sbin/nginx ]; then
    echo "Nginx with RTMP not found. Please run: sudo bash setup_nginx_rtmp.sh"
    exit 1
fi

# Stop system nginx if running
echo "Stopping system nginx (if running)..."
sudo systemctl stop nginx 2>/dev/null

# Kill any existing /usr/local/nginx processes
echo "Killing any existing /usr/local/nginx processes..."
sudo pkill -f "/usr/local/nginx" 2>/dev/null

# Wait a moment
sleep 2

# Copy updated config
echo "Copying nginx RTMP configuration..."
sudo cp nginx/nginx.conf /usr/local/nginx/conf/nginx.conf

# Test config
echo "Testing nginx configuration..."
sudo /usr/local/nginx/sbin/nginx -t
if [ $? -ne 0 ]; then
    echo "Error: nginx configuration test failed!"
    exit 1
fi

# Start nginx
echo "Starting nginx RTMP server..."
sudo /usr/local/nginx/sbin/nginx

# Wait a bit for nginx to start
sleep 2

# Start Django
echo "Starting Django server..."
python manage.py runserver 0.0.0.0:8000
