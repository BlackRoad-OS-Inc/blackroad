#!/bin/zsh
# Setup nginx on DigitalOcean droplet as BlackRoad mirror
# DO Droplet: 159.65.43.12 (blackroad-os-infinity)

DO_IP="159.65.43.12"
DO_USER="root"

echo "Setting up nginx mirror on DO droplet $DO_IP..."

# Create nginx config locally
cat > /tmp/do-nginx.conf << 'NGINX'
server {
    listen 80 default_server;
    server_name _;
    
    # Health check
    location /health {
        return 200 '{"status":"ok","node":"do-infinity"}';
        add_header Content-Type application/json;
    }
    
    # Proxy to Pi tunnel if available
    location / {
        proxy_pass https://blackroad.io;
        proxy_set_header Host blackroad.io;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_connect_timeout 5s;
        proxy_read_timeout 10s;
        error_page 502 503 504 /fallback.html;
    }
    
    location /fallback.html {
        root /var/www/html;
        internal;
    }
}
NGINX

echo "Nginx config created at /tmp/do-nginx.conf"
echo "Deploy with: scp /tmp/do-nginx.conf root@$DO_IP:/etc/nginx/sites-available/blackroad"
echo "Then: ssh root@$DO_IP 'ln -sf /etc/nginx/sites-available/blackroad /etc/nginx/sites-enabled/ && nginx -t && systemctl reload nginx'"
