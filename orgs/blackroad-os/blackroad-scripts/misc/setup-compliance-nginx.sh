#!/bin/bash

echo "🖤🛣️ Setting up Nginx reverse proxy for compliance dashboard..."

# Create nginx config on Alice Pi
ssh pi@192.168.4.49 "sudo tee /etc/nginx/sites-available/compliance.blackroad.io > /dev/null" << 'NGINX'
server {
    listen 80;
    server_name compliance.blackroad.io;

    location / {
        proxy_pass http://localhost:8084;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
NGINX

echo "✅ Nginx config created"

# Enable the site
ssh pi@192.168.4.49 "sudo ln -sf /etc/nginx/sites-available/compliance.blackroad.io /etc/nginx/sites-enabled/"

echo "✅ Site enabled"

# Test and reload nginx
ssh pi@192.168.4.49 "sudo nginx -t && sudo systemctl reload nginx"

echo "✅ Nginx reloaded"
echo ""
echo "Now access the dashboard at:"
echo "  http://192.168.4.49 (if you set up local DNS)"
echo "  or http://192.168.4.49:8084 (direct)"
echo ""
