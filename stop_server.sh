#!/bin/bash

echo "Stopping streaming server..."

# Stop nginx
if [ -f /usr/local/nginx/sbin/nginx ]; then
    echo "Stopping nginx..."
    sudo /usr/local/nginx/sbin/nginx -s stop
fi

# Django will be stopped by Ctrl+C
echo "Press Ctrl+C to stop Django server"
