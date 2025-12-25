#!/bin/bash
# Production Setup Script for OBS Streaming Server
# Run with: sudo bash setup_production.sh

set -e  # Exit on error

echo "=========================================="
echo "OBS Streaming Server - Production Setup"
echo "=========================================="
echo ""

# Check if running as root
if [ "$EUID" -ne 0 ]; then 
    echo "Please run as root: sudo bash setup_production.sh"
    exit 1
fi

# Get the actual user (not root)
ACTUAL_USER=${SUDO_USER:-$USER}
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

echo "Working directory: $SCRIPT_DIR"
echo "Running as: $ACTUAL_USER"
echo ""

# 1. Setup System nginx reverse proxy config
echo "[1/6] Setting up System nginx reverse proxy..."
cat > /etc/nginx/sites-available/streaming << 'EOF'
server {
    listen 80;
    server_name 206.162.244.150;

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

# Enable site and remove default
ln -sf /etc/nginx/sites-available/streaming /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default

echo "✓ System nginx config created"

# 2. Copy custom nginx config
echo "[2/6] Configuring custom nginx (RTMP/HLS)..."
if [ ! -d "/usr/local/nginx" ]; then
    echo "Error: /usr/local/nginx not found. Please run: sudo bash setup_nginx_rtmp.sh"
    exit 1
fi

cp -f "$SCRIPT_DIR/nginx/nginx.conf" /usr/local/nginx/conf/nginx.conf
echo "✓ Custom nginx config copied"

# 3. Test nginx configs
echo "[3/6] Testing nginx configurations..."
nginx -t
/usr/local/nginx/sbin/nginx -t
echo "✓ Both nginx configs are valid"

# 4. Create systemd service for custom nginx
echo "[4/6] Creating systemd service for custom nginx..."
cat > /etc/systemd/system/nginx-rtmp.service << 'EOF'
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
EOF

echo "✓ nginx-rtmp systemd service created"

# 5. Create systemd service for Django
echo "[5/6] Creating systemd service for Django..."
cat > /etc/systemd/system/streaming_server.service << EOF
[Unit]
Description=Gunicorn for streaming_server
After=network.target

[Service]
User=$ACTUAL_USER
Group=$ACTUAL_USER
WorkingDirectory=$SCRIPT_DIR
Environment="PATH=$SCRIPT_DIR/.venv/bin"
ExecStart=$SCRIPT_DIR/.venv/bin/gunicorn streaming_server.wsgi:application \\
  --bind 127.0.0.1:8000 --workers 3
Restart=always

[Install]
WantedBy=multi-user.target
EOF

echo "✓ streaming_server systemd service created"

# 6. Configure firewall
echo "[6/6] Configuring firewall..."
ufw allow 80/tcp comment 'HTTP'
ufw allow 443/tcp comment 'HTTPS'
ufw allow 1935/tcp comment 'RTMP'
ufw --force enable
echo "✓ Firewall configured"

# Reload systemd
systemctl daemon-reload

echo ""
echo "=========================================="
echo "✅ Production setup complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo ""
echo "1. Install gunicorn (if not already):"
echo "   source .venv/bin/activate"
echo "   pip install gunicorn"
echo ""
echo "2. Start all services:"
echo "   sudo systemctl start nginx"
echo "   sudo systemctl start nginx-rtmp"
echo "   sudo systemctl start streaming_server"
echo ""
echo "3. Enable auto-start on boot:"
echo "   sudo systemctl enable nginx"
echo "   sudo systemctl enable nginx-rtmp"
echo "   sudo systemctl enable streaming_server"
echo ""
echo "4. Check status:"
echo "   sudo systemctl status nginx"
echo "   sudo systemctl status nginx-rtmp"
echo "   sudo systemctl status streaming_server"
echo ""
echo "5. View logs:"
echo "   sudo journalctl -u streaming_server -f"
echo "   sudo tail -f /usr/local/nginx/logs/error.log"
echo ""
echo "Your streaming server will be available at:"
echo "  - Web: http://206.162.244.150/"
echo "  - RTMP: rtmp://206.162.244.150:1935/live/{STREAM_KEY}"
echo "  - HLS: http://206.162.244.150/live/{STREAM_KEY}.m3u8"
echo ""
