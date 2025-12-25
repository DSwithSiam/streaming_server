#!/bin/bash

# Quick start script for the streaming server

echo "Starting OBS Streaming Server..."

# Check if nginx is installed
if [ ! -f /usr/local/nginx/sbin/nginx ]; then
    echo "Nginx with RTMP not found. Please run: sudo bash setup_nginx_rtmp.sh"
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
