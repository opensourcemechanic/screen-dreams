# Podman Port 8080 Deployment Guide

## Default Local Deployment Method

**Port 8080 is now the recommended default for all local Podman deployments** to avoid privileged port restrictions and ensure compatibility across different environments.

## Why Port 8080?

### Problems with Port 80:
- **Privileged Port**: Requires root/sudo permissions
- **Podman Rootless**: Cannot bind to ports < 1024
- **Security Issues**: Complex permission setup
- **Cross-Platform**: Different behavior on different systems

### Benefits of Port 8080:
- **Non-Privileged**: Works without special permissions
- **Rootless Compatible**: Perfect for Podman
- **Universal**: Works everywhere
- **Simple**: No configuration needed

## Quick Deployment

```bash
# Clone and deploy
git clone https://github.com/opensourcemechanic/screen-dreams.git
cd screen-dreams
chmod +x podman-deploy-8080.sh
./podman-deploy-8080.sh
```

## Access Methods

### Primary (Recommended)
- **URL**: `http://localhost:8080`
- **Features**: Nginx reverse proxy, static files, security headers
- **Use**: All local development and testing

### Direct Flask Access
- **URL**: `http://localhost:5000`
- **Features**: Direct app access, debugging
- **Use**: Development and troubleshooting

### External Access
- **URL**: `http://YOUR_SERVER_IP:8080`
- **Features**: Remote access to nginx proxy
- **Use**: Team development, client demos

## Port Forwarding (Optional)

If you need port 80 access for production:

### Method 1: iptables Forwarding
```bash
# Forward port 80 to 8080
sudo iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-port 8080

# Make persistent
sudo apt install -y iptables-persistent
sudo netfilter-persistent save
```

### Method 2: Nginx Host Proxy
```bash
# Install nginx on host
sudo apt install -y nginx

# Configure proxy to port 8080
sudo tee /etc/nginx/sites-available/screen-dreams << 'EOF'
server {
    listen 80;
    server_name localhost;
    
    location / {
        proxy_pass http://localhost:8080;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
EOF

# Enable and restart
sudo ln -s /etc/nginx/sites-available/screen-dreams /etc/nginx/sites-enabled/
sudo nginx -t && sudo systemctl restart nginx
```

## Container Architecture

```
Internet (Port 8080)
    |
    v
Nginx Container (Port 80)
    |
    v
Flask App Container (Port 5000)
    |
    v
Redis Container (Port 6379)
```

## Environment-Specific Ports

| Environment | Port 80 | Port 8080 | Port 5000 | Recommended |
|-------------|---------|-----------|-----------|-------------|
| Local Podman | No | Yes | Yes | **8080** |
| Local Docker | Yes | Yes | Yes | 80 or 8080 |
| Production | Yes | No | No | **80** |
| Development | No | Yes | Yes | **8080** |

## Troubleshooting

### Port 8080 Not Accessible
```bash
# Check if port is bound
netstat -tlnp | grep :8080

# Check container status
podman ps

# Check logs
podman logs screen-dreams-nginx-dev
```

### External Access Issues
```bash
# Check firewall
sudo ufw status
sudo ufw allow 8080/tcp

# Check cloud provider firewall
# Add inbound rule for port 8080
```

### Container Communication
```bash
# Test pod networking
podman exec -it screen-dreams-dev ping screen-dreams-redis-dev

# Check service discovery
podman exec -it screen-dreams-dev curl screen-dreams-redis-dev:6379
```

## Production Migration

When moving from local (port 8080) to production (port 80):

### 1. Update Configuration
```bash
# Use production deployment script
./deploy-docker-simple.sh  # Docker
# or
./terraform-apply.sh        # Terraform
```

### 2. Update DNS/Firewall
```bash
# Update firewall rules
sudo ufw delete allow 8080/tcp
sudo ufw allow 80/tcp

# Update DNS records
# Point domain to production server
```

### 3. Update Application URLs
```bash
# Update any hardcoded URLs
# from: http://localhost:8080
# to:   http://yourdomain.com
```

## Best Practices

### Development
- **Always use port 8080** for local development
- **Test on port 5000** for direct app access
- **Use port 8080** for team sharing

### Production
- **Use port 80** for public access
- **Set up HTTPS** with SSL certificates
- **Use load balancers** for scaling

### Security
- **Keep port 5000 internal** (don't expose externally)
- **Use firewalls** to restrict access
- **Monitor access logs** for security

## Summary

**Port 8080 is the standard for local development** because:
- It works everywhere without special permissions
- It avoids all privileged port issues
- It's compatible with Podman rootless containers
- It's easy to remember and use

**Use port 8080 for all local development** and only switch to port 80 when deploying to production.
