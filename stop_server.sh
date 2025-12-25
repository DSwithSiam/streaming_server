#!/bin/bash

echo "Stopping OBS Streaming Server..."

# Stop nginx
echo "Stopping nginx RTMP server..."
sudo /usr/local/nginx/sbin/nginx -s quit
sleep 1

# Make sure it's dead
sudo pkill -f "/usr/local/nginx" 2>/dev/null

# Find and kill Django server
echo "Stopping Django server..."
pkill -f "manage.py runserver" 2>/dev/null

echo "Server stopped."
