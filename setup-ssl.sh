#!/bin/bash
# SSL Certificate Setup Script for Screen Dreams Screenwriter
# This script sets up Let's Encrypt SSL certificates

set -e

# Configuration
DOMAIN="${1:-your-domain.com}"
EMAIL="${2:-admin@your-domain.com}"
WEBROOT="/var/www/html"

echo "🔐 Setting up SSL certificates for $DOMAIN"

# Check if running as root
if [[ $EUID -ne 0 ]]; then
   echo "❌ This script must be run as root (use sudo)" 
   exit 1
fi

# Install Certbot if not present
if ! command -v certbot &> /dev/null; then
    echo "📦 Installing Certbot..."
    apt-get update
    apt-get install -y certbot python3-certbot-nginx
fi

# Create webroot directory
mkdir -p $WEBROOT
chown www-data:www-data $WEBROOT

# Stop nginx temporarily
echo "🛑 Stopping Nginx temporarily..."
systemctl stop nginx

# Obtain SSL certificate
echo "🔑 Obtaining SSL certificate for $DOMAIN..."
certbot certonly \
    --standalone \
    --email $EMAIL \
    --agree-tos \
    --no-eff-email \
    --domains $DOMAIN,www.$DOMAIN

# Copy nginx configuration
echo "📋 Setting up Nginx HTTPS configuration..."
cp /opt/screen-dreams/nginx-https.conf /etc/nginx/sites-available/screen-dreams-https

# Update domain in nginx config
sed -i "s/your-domain.com/$DOMAIN/g" /etc/nginx/sites-available/screen-dreams-https

# Enable the site
ln -sf /etc/nginx/sites-available/screen-dreams-https /etc/nginx/sites-enabled/
rm -f /etc/nginx/sites-enabled/default
rm -f /etc/nginx/sites-enabled/screen-dreams

# Test nginx configuration
echo "🧪 Testing Nginx configuration..."
nginx -t

# Start nginx
echo "🚀 Starting Nginx with HTTPS..."
systemctl start nginx
systemctl enable nginx

# Setup auto-renewal
echo "🔄 Setting up automatic certificate renewal..."
cat > /etc/cron.d/certbot-renew << EOF
# Renew Let's Encrypt certificates twice daily
0 */12 * * * root certbot renew --quiet --post-hook "systemctl reload nginx"
EOF

# Test auto-renewal
certbot renew --dry-run

echo "✅ SSL setup complete!"
echo "🌐 Your site should now be available at: https://$DOMAIN"
echo "🔒 SSL certificate will auto-renew every 12 hours"

# Display certificate info
echo "📋 Certificate information:"
certbot certificates
