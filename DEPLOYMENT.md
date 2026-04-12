# Screen Dreams Screenwriter - Deployment Guide

## Local Development Deployment

### Quick Start

```bash
# Install dependencies
pip install -r requirements.txt

# Run development server
python3 run.py
```

Access at: http://localhost:5000

### Development Features

- ✅ Debug mode enabled
- ✅ Auto-restart on code changes
- ✅ Detailed error messages
- ✅ SQLite database in project directory
- ✅ Static files served by Flask

### Environment Setup

```bash
# Create virtual environment
python3 -m venv venv
source venv/bin/activate  # Linux/Mac
# or
venv\Scripts\activate     # Windows

# Install dependencies
pip install -r requirements.txt

# Copy environment file
cp .env.example .env
# Edit .env with your settings
```

### Local Configuration

The development server uses Flask's built-in server:
- Port: 5000
- Host: 127.0.0.1 (localhost)
- Debug: True
- Auto-reload: True

### Database

Development uses SQLite:
```bash
# Database file location
screenwriter.db

# Reset database
rm screenwriter.db
python3 run.py  # Will recreate automatically
```

## Podman Container Deployment

### Overview

Podman is a daemonless container engine that provides Docker-compatible CLI but with better security and no central daemon. It's ideal for rootless deployments and development environments.

### Quick Start

```bash
# Clone repository
git clone https://github.com/opensourcemechanic/screen-dreams.git
cd screen-dreams

# Deploy with unified script (recommended)
chmod +x podman-deploy-unified.sh
./podman-deploy-unified.sh

# Access application
http://localhost:8080    # Nginx proxy (default)
http://localhost:5000    # Direct Flask access
```

### Deployment Options

#### Option 1: Unified Script (Recommended)
```bash
# Default deployment (port 8080, lightweight, auto-registry)
./podman-deploy-unified.sh

# Port 80 deployment (requires sudo/privileged)
./podman-deploy-unified.sh --port-80

# Full image names (bypasses registry issues)
./podman-deploy-unified.sh --full-image-names

# Lightweight build (Alpine Linux)
./podman-deploy-unified.sh --lightweight

# Standard build (Debian)
./podman-deploy-unified.sh --standard-build
```

#### Option 2: Specialized Scripts
```bash
# Port 8080 specific deployment
./podman-deploy-8080.sh

# Quick fix with full image names
./podman-deploy-quick-fix.sh

# Standard deployment
./podman-deploy-fixed.sh
```

### Directory Structure

```
screen-dreams/              # Project directory (current directory)
  uploads/                  # User uploaded files
  screenplays/             # Generated screenplays
  logs/                    # Application logs
  docker/                  # Docker/Podman configurations
    nginx/
      default.conf         # Nginx reverse proxy config
  .env                     # Environment variables
  Dockerfile.dev           # Development container build
  Dockerfile.dev.podman    # Lightweight Alpine build
  docker-compose.dev.yml  # Docker Compose configuration
```

**Note**: For Podman deployment, all files are used from the current project directory. No separate `/opt/screen-dreams` installation is required.

### Container Architecture

```
Pod: screen-dreams-pod
  |
  +-- Container: screen-dreams-dev (Flask App)
  |      Port: 5000 (internal)
  |      Image: screen-dreams:lightweight
  |      Volumes: ./uploads, ./screenplays, ./logs
  |
  +-- Container: screen-dreams-nginx-dev (Nginx Proxy)
  |      Port: 8080 (host) -> 80 (container)
  |      Image: nginx:alpine
  |      Config: ./docker/nginx/default.conf
  |
  +-- Container: screen-dreams-redis-dev (Redis Cache)
         Port: 6379 (internal)
         Image: redis:7-alpine
```

### Service Configuration

#### Environment Variables (.env)
```bash
# Flask Configuration
FLASK_ENV=development
SECRET_KEY=dev-secret-key-change-in-production

# Database Configuration
DATABASE_URL=sqlite:///screenwriter_dev.db

# Redis Configuration
REDIS_URL=redis://redis-dev:6379/0
RATELIMIT_STORAGE_URL=redis://redis-dev:6379/0

# AI Assistant Configuration
AI_PROVIDER=ollama
OLLAMA_BASE_URL=http://ollama-dev:11434
OLLAMA_MODEL=llama2
OLLAMA_TIMEOUT=300
```

#### Nginx Configuration (docker/nginx/default.conf)
```nginx
upstream screen-dreams-backend {
    server screen-dreams-dev:5000;
}

server {
    listen 80;
    server_name localhost;

    # Security headers
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    add_header Referrer-Policy "strict-origin-when-cross-origin";

    # Static files
    location /static {
        alias /var/www/static;
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # Main application
    location / {
        proxy_pass http://screen-dreams-backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
    }

    # Health check
    location /health {
        proxy_pass http://screen-dreams-backend;
        access_log off;
    }
}
```

### Container Build Options

#### Option 1: Lightweight Alpine (Default)
```dockerfile
FROM python:3.11-alpine

# Install minimal dependencies
RUN apk add --no-cache gcc musl-dev libpq-dev curl vim git

# Install Python requirements
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application
COPY . .

# Run application
CMD ["python3", "run_dev.py"]
```

#### Option 2: Standard Debian
```dockerfile
FROM python:3.11-slim

# Install system dependencies
RUN apt-get update && apt-get install -y gcc g++ libpq-dev curl vim git

# Install Python requirements
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application
COPY . .

# Run application
CMD ["python3", "run_dev.py"]
```

### Registry Configuration

Podman may require registry configuration for short image names:

#### Automatic Configuration
```bash
# The unified script handles this automatically
./podman-deploy-unified.sh
```

#### Manual Configuration
```bash
# Create system registry config
sudo mkdir -p /etc/containers
echo '[registries.search]
registries = ["docker.io"]' | sudo tee /etc/containers/registries.conf

# Create user registry config
mkdir -p ~/.config/containers
echo '[registries.search]
registries = ["docker.io"]' > ~/.config/containers/registries.conf
```

#### Full Image Names (Bypass Registry)
```bash
# Use full image names to avoid registry issues
./podman-deploy-unified.sh --full-image-names

# This uses images like:
# docker.io/library/redis:7-alpine
# docker.io/library/nginx:alpine
```

### Port Configuration

#### Port 8080 (Default - Recommended)
- **Advantages**: No privileged port issues, works everywhere
- **Use Case**: Local development, testing, most environments
- **Access**: http://localhost:8080

#### Port 80 (Production)
- **Advantages**: Standard HTTP port, user-friendly URLs
- **Requirements**: Proper permissions, firewall configuration
- **Use Case**: Production deployments with proper setup
- **Access**: http://localhost

#### Port Forwarding
```bash
# Forward port 80 to 8080 (if needed)
sudo iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-port 8080

# Make persistent
sudo apt install -y iptables-persistent
sudo netfilter-persistent save
```

### Management Commands

#### Container Operations
```bash
# View running containers
podman ps

# View container logs
podman logs -f screen-dreams-dev
podman logs -f screen-dreams-nginx-dev
podman logs -f screen-dreams-redis-dev

# Restart containers
podman restart screen-dreams-dev
podman restart screen-dreams-nginx-dev

# Stop all containers
podman stop -a

# Remove all containers
podman rm -a

# Remove pod
podman pod rm screen-dreams-pod
```

#### Image Management
```bash
# List images
podman images

# Build new image
podman build -t screen-dreams:custom -f Dockerfile.dev .

# Remove unused images
podman image prune -f

# Remove all images
podman rmi -a
```

#### System Cleanup
```bash
# Clean up everything
podman system prune -a

# Clean up volumes
podman volume prune

# Check disk usage
podman system df
```

### Production Considerations

#### Security
- **Rootless Containers**: Podman runs containers without root by default
- **Pod Isolation**: Containers share network but are isolated otherwise
- **File Permissions**: Ensure proper permissions for volumes
- **Environment Variables**: Keep sensitive data in .env file

#### Performance
- **Lightweight Images**: Use Alpine for smaller footprint
- **Resource Limits**: Set memory and CPU limits in production
- **Health Checks**: Monitor container health and restart policies
- **Logging**: Configure proper log rotation

#### Persistence
- **Data Volumes**: Use bind mounts for uploads and screenplays
- **Database**: SQLite file persists in project directory
- **Backups**: Regular backups of uploads and screenplays directories
- **State Management**: Redis data is ephemeral (cache only)

#### Monitoring
```bash
# Check container resource usage
podman stats

# Check container health
podman exec screen-dreams-dev curl localhost:5000/health

# Monitor logs
podman logs -f --tail=100 screen-dreams-dev
```

### Troubleshooting

#### Common Issues

**Port Binding Errors**
```bash
# Use port 8080 instead of 80
./podman-deploy-unified.sh --port-8080

# Or fix privileged port permissions
sudo sysctl -w net.ipv4.ip_unprivileged_port_start=80
```

**Registry Resolution Errors**
```bash
# Use full image names
./podman-deploy-unified.sh --full-image-names

# Or configure registry
./podman-deploy-unified.sh --registry-config
```

**Container Communication Issues**
```bash
# Test pod networking
podman exec -it screen-dreams-dev ping redis-dev

# Check service discovery
podman exec -it screen-dreams-dev curl redis-dev:6379
```

**Permission Issues**
```bash
# Check file permissions
ls -la uploads/ screenplays/ logs/

# Fix permissions
chmod 755 uploads screenplays logs
```

#### Debug Commands
```bash
# Enter container for debugging
podman exec -it screen-dreams-dev /bin/sh

# Check container processes
podman exec -it screen-dreams-dev ps aux

# Test application inside container
podman exec -it screen-dreams-dev curl localhost:5000/health

# Check network configuration
podman exec -it screen-dreams-dev netstat -tlnp
```

### Migration from Docker

If migrating from Docker to Podman:

```bash
# Export Docker images (if needed)
docker save screen-dreams:latest | podman load

# Use Docker Compose equivalent
# Podman doesn't support docker-compose directly
# Use the provided Podman scripts instead

# Update deployment scripts
# Replace docker commands with podman commands
# Use podman pods instead of docker networks
```

---

## Production Deployment Guide

### Architecture Overview

```
Internet → Nginx (SSL/Static Files) → Gunicorn (WSGI) → Flask App → SQLite DB
```

### 1. Server Requirements

**Minimum:**
- CPU: 2 cores
- RAM: 2GB
- Storage: 10GB SSD
- OS: Ubuntu 20.04+ / CentOS 8+ / Debian 10+

**Recommended:**
- CPU: 4+ cores
- RAM: 4GB+
- Storage: 50GB+ SSD
- OS: Ubuntu 22.04 LTS

### 2. Gunicorn Configuration

Create `gunicorn.conf.py`:

```python
# Gunicorn production configuration
import multiprocessing
import os

# Server socket
bind = "127.0.0.1:8000"
backlog = 2048

# Worker processes (optimized for production)
workers = min(multiprocessing.cpu_count() * 2 + 1, 9)
worker_class = "sync"
worker_connections = 1000
timeout = 30
keepalive = 2

# Logging
accesslog = "/var/log/screen-dreams/access.log"
errorlog = "/var/log/screen-dreams/error.log"
loglevel = "info"
access_log_format = '%(h)s %(l)s %(u)s %(t)s "%(r)s" %(s)s %(b)s "%(f)s" "%(a)s" %(D)s'

# Process naming
proc_name = "screen-dreams"

# Server mechanics
daemon = False
pidfile = "/var/run/screen-dreams/gunicorn.pid"
user = "www-data"
group = "www-data"
tmp_upload_dir = None

# Graceful shutdown and restarts
max_requests = 1000
max_requests_jitter = 100
preload_app = True

# Security
limit_request_line = 4094
limit_request_fields = 100
limit_request_field_size = 8190
```

### 3. Auto-Restart Services

#### HTTPS Configuration

### SSL Certificate Setup

For production deployment, HTTPS is strongly recommended for security.

#### Option 1: Let's Encrypt (Recommended)

```bash
# Run the SSL setup script
sudo chmod +x /opt/screen-dreams/setup-ssl.sh
sudo /opt/screen-dreams/setup-ssl.sh your-domain.com admin@your-domain.com
```

#### Option 2: Manual Let's Encrypt Setup

```bash
# Install Certbot
sudo apt-get update
sudo apt-get install certbot python3-certbot-nginx

# Obtain certificate
sudo certbot certonly --standalone -d your-domain.com -d www.your-domain.com

# Copy and configure Nginx HTTPS config
sudo cp /opt/screen-dreams/nginx-https.conf /etc/nginx/sites-available/screen-dreams-https
sudo sed -i 's/your-domain.com/your-actual-domain.com/g' /etc/nginx/sites-available/screen-dreams-https

# Enable HTTPS site
sudo ln -sf /etc/nginx/sites-available/screen-dreams-https /etc/nginx/sites-enabled/
sudo rm -f /etc/nginx/sites-enabled/screen-dreams

# Test and reload
sudo nginx -t
sudo systemctl reload nginx
```

#### Option 3: Custom SSL Certificates

If using custom SSL certificates, place them in `/etc/ssl/certs/` and update the nginx configuration:

```nginx
ssl_certificate /etc/ssl/certs/your-domain.crt;
ssl_certificate_key /etc/ssl/private/your-domain.key;
```

### Environment Configuration for HTTPS

Update your `.env` file:

```bash
# Copy example configuration
cp /opt/screen-dreams/.env.example /opt/screen-dreams/.env

# Edit configuration
sudo nano /opt/screen-dreams/.env
```

Key HTTPS settings:
```bash
FORCE_HTTPS=True
PREFERRED_URL_SCHEME=https
SESSION_COOKIE_SECURE=True
REMEMBER_COOKIE_SECURE=True
```

## AI Provider Configuration

### Remote Ollama Server (HTTPS)

For secure remote Ollama deployment:

```bash
# In .env file
AI_PROVIDER=ollama
OLLAMA_BASE_URL=https://your-ollama-server.com:11434
OLLAMA_API_KEY=your-api-key-if-required
OLLAMA_VERIFY_SSL=true
OLLAMA_MODEL=llama2
```

### OpenAI Configuration

```bash
# In .env file
AI_PROVIDER=openai
OPENAI_API_KEY=your-openai-api-key
OPENAI_MODEL=gpt-3.5-turbo
```

### Anthropic Claude Configuration

```bash
# In .env file
AI_PROVIDER=anthropic
ANTHROPIC_API_KEY=your-anthropic-api-key
ANTHROPIC_MODEL=claude-3-sonnet-20240229
```

### Multiple AI Provider Setup

You can configure multiple providers and switch between them:

```bash
# Primary provider
AI_PROVIDER=ollama

# Ollama configuration
OLLAMA_BASE_URL=https://ollama.example.com:11434
OLLAMA_API_KEY=ollama-key

# OpenAI backup
OPENAI_API_KEY=openai-key

# Anthropic backup
ANTHROPIC_API_KEY=anthropic-key
```

## Security Best Practices

### Firewall Configuration

```bash
# Allow only necessary ports
sudo ufw enable
sudo ufw allow 22/tcp    # SSH
sudo ufw allow 80/tcp    # HTTP (redirects to HTTPS)
sudo ufw allow 443/tcp   # HTTPS
```

### SSL Security Headers

The nginx configuration includes security headers:
- `Strict-Transport-Security` - Force HTTPS
- `X-Frame-Options` - Prevent clickjacking
- `X-Content-Type-Options` - Prevent MIME sniffing
- `Content-Security-Policy` - XSS protection

### Rate Limiting

Built-in rate limiting for:
- Login attempts: 5 per minute
- API calls: 10 per second
- General requests: Configurable

### File Permissions

```bash
# Secure file permissions
sudo chown -R www-data:www-data /opt/screen-dreams
sudo chmod -R 755 /opt/screen-dreams
sudo chmod 600 /opt/screen-dreams/.env
sudo chmod 600 /etc/ssl/private/*
```

Create `/etc/systemd/system/screen-dreams.service`:

```ini
[Unit]
Description=Screen Dreams Screenwriter Web Application
After=network.target
Wants=network.target

[Service]
Type=notify
User=www-data
Group=www-data
WorkingDirectory=/opt/screen-dreams
Environment=PATH=/opt/screen-dreams/venv/bin
EnvironmentFile=/opt/screen-dreams/.env
ExecStart=/opt/screen-dreams/venv/bin/gunicorn --config gunicorn.conf.py run:app
ExecReload=/bin/kill -s HUP $MAINPID
Restart=always
RestartSec=5

# Security
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/opt/screen-dreams /var/log/screen-dreams /var/run/screen-dreams

[Install]
WantedBy=multi-user.target
```

```bash
# Create necessary directories and permissions
sudo mkdir -p /opt/screen-dreams
sudo mkdir -p /var/log/screen-dreams
sudo mkdir -p /var/run/screen-dreams
sudo chown www-data:www-data /opt/screen-dreams
sudo chown www-data:www-data /var/log/screen-dreams
sudo chown www-data:www-data /var/run/screen-dreams

# Enable and start service
sudo systemctl daemon-reload
sudo systemctl enable screen-dreams
sudo systemctl start screen-dreams
sudo systemctl status screen-dreams
```

#### Windows (NSSM - Non-Sucking Service Manager)

```powershell
# Install NSSM
# Download from https://nssm.cc/download
# Extract and add to PATH

# Create service
nssm install ScreenDreams "C:\opt\screen-dreams\venv\Scripts\gunicorn.exe"
nssm set ScreenDreams Arguments "--config gunicorn.conf.py run:app"
nssm set ScreenDreams Directory "C:\opt\screen-dreams"
nssm set ScreenDreams DisplayName "Screen Dreams Screenwriter"
nssm set ScreenDreams Description "Screen Dreams Screenwriter Web Application"
nssm set ScreenDreams Start SERVICE_AUTO_START
nssm set ScreenDreams AppEnvironmentExtra "PYTHONPATH=C:\opt\screen-dreams"

# Start service
nssm start ScreenDreams
```

#### macOS (launchd)

Create `/Library/LaunchDaemons/com.screen.dreams.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.screen.dreams</string>
    <key>ProgramArguments</key>
    <array>
        <string>/opt/screen-dreams/venv/bin/gunicorn</string>
        <string>--config</string>
        <string>gunicorn.conf.py</string>
        <string>run:app</string>
    </array>
    <key>WorkingDirectory</key>
    <string>/opt/screen-dreams</string>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/var/log/screen-dreams/access.log</string>
    <key>StandardErrorPath</key>
    <string>/var/log/screen-dreams/error.log</string>
    <key>UserName</key>
    <string>www</string>
    <key>GroupName</key>
    <string>www</string>
</dict>
</plist>
```

```bash
# Load and start service
sudo launchctl load /Library/LaunchDaemons/com.screen.dreams.plist
sudo launchctl start com.screen.dreams
```

### 4. Nginx Reverse Proxy

Install Nginx:
```bash
# Ubuntu/Debian
sudo apt update
sudo apt install nginx

# CentOS/RHEL
sudo yum install nginx
# or
sudo dnf install nginx
```

Create `/etc/nginx/sites-available/screenplay-editor`:

```nginx
server {
    listen 80;
    server_name your-domain.com www.your-domain.com;
    
    # Redirect to HTTPS
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl http2;
    server_name your-domain.com www.your-domain.com;
    
    # SSL Configuration
    ssl_certificate /etc/letsencrypt/live/your-domain.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/your-domain.com/privkey.pem;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers ECDHE-RSA-AES256-GCM-SHA512:DHE-RSA-AES256-GCM-SHA512:ECDHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES256-GCM-SHA384;
    ssl_prefer_server_ciphers off;
    ssl_session_cache shared:SSL:10m;
    ssl_session_timeout 10m;
    
    # Security Headers
    add_header X-Frame-Options DENY;
    add_header X-Content-Type-Options nosniff;
    add_header X-XSS-Protection "1; mode=block";
    add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;
    
    # Gzip Compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_proxied any;
    gzip_comp_level 6;
    gzip_types
        text/plain
        text/css
        text/xml
        text/javascript
        application/json
        application/javascript
        application/xml+rss
        application/atom+xml
        image/svg+xml;
    
    # Static Files (served directly by Nginx)
    location /static {
        alias /opt/screenplay-editor/static;
        expires 1y;
    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
        
        # Buffer settings
        proxy_buffering on;
        proxy_buffer_size 4k;
        proxy_buffers 8 4k;
    }
    
    # API rate limiting
    location /api/ {
        limit_req zone=api burst=20 nodelay;
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
    
    # Static Files (served directly by Nginx)
    location /static {
        alias /opt/screen-dreams/static;
        expires 1y;
        add_header Cache-Control "public, immutable";
        add_header X-Content-Type-Options nosniff;
        
        # Security for static files
        location ~* \.(?:css|js)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
        
        location ~* \.(?:png|jpg|jpeg|gif|ico|svg)$ {
            expires 1y;
            add_header Cache-Control "public, immutable";
        }
    }
    
    # Health Check
    location /health {
        access_log off;
        proxy_pass http://127.0.0.1:8000/health;
    }
    
    # Security: Block access to sensitive files
    location ~ /\. {
        deny all;
    }
    
    location ~ \.(py|pyc|pyo|db)$ {
        deny all;
    }
}
```

Enable site:
```bash
sudo ln -s /etc/nginx/sites-available/screen-dreams /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

### 5. SSL Certificate with Let's Encrypt

```bash
# Install Certbot
sudo apt install certbot python3-certbot-nginx

# Get SSL certificate
sudo certbot --nginx -d your-domain.com -d www.your-domain.com

# Auto-renewal
sudo crontab -e
# Add: 0 12 * * * /usr/bin/certbot renew --quiet
```

### 6. Production Environment Variables

Create `/opt/screen-dreams/.env`:

```bash
# Flask Configuration
FLASK_ENV=production
SECRET_KEY=your-very-secure-secret-key-here

# Database Configuration
# For SQLite: sqlite:///screenwriter.db
# For PostgreSQL: postgresql://user:password@localhost/screenwriter

# Application Settings
SCREENPLAY_FOLDER=/opt/screen-dreams/screenplays
MAX_CONTENT_LENGTH=16777216  # 16MB max upload

# AI Assistant (Ollama)
OLLAMA_MODEL=llama2
OLLAMA_BASE_URL=http://localhost:11434
OLLAMA_TIMEOUT=300

# Logging
LOG_LEVEL=INFO
LOG_FILE=/var/log/screen-dreams/app.log

# Security
RATELIMIT_STORAGE_URL=redis://localhost:6379/1
SESSION_COOKIE_SECURE=True
SESSION_COOKIE_HTTPONLY=True
SESSION_COOKIE_SAMESITE=Lax

# Performance
CACHE_TYPE=redis
CACHE_REDIS_URL=redis://localhost:6379/0
```

### 7. Production Flask App Updates

Update `app/__init__.py` for production:

```python
import os
from flask import Flask
from flask_sqlalchemy import SQLAlchemy
import logging
from logging.handlers import RotatingFileHandler

db = SQLAlchemy()

def create_app(config_name=None):
    app = Flask(__name__, 
                template_folder='../templates',
                static_folder='../static')
    
    # Load configuration
    if config_name == 'production' or os.environ.get('FLASK_ENV') == 'production':
        app.config['DEBUG'] = False
        app.config['TESTING'] = False
        app.config['SECRET_KEY'] = os.environ.get('SECRET_KEY', 'dev-secret-key')
        app.config['SQLALCHEMY_DATABASE_URI'] = os.environ.get('DATABASE_URL', 'sqlite:///screenwriter.db')
        app.config['SQLALCHEMY_ENGINE_OPTIONS'] = {
            'pool_size': 10,
            'pool_recycle': 120,
            'pool_pre_ping': True
        }
    else:
        # Development configuration
        app.config['SECRET_KEY'] = os.environ.get('SECRET_KEY', 'dev-secret-key-change-in-production')
        app.config['SQLALCHEMY_DATABASE_URI'] = 'sqlite:///screenwriter.db'
        app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False
        app.config['SCREENPLAY_FOLDER'] = os.path.join(os.path.dirname(os.path.dirname(__file__)), 'screenplays')
    
    # Initialize extensions
    db.init_app(app)
    
    # Setup logging for production
    if app.config.get('ENV') == 'production':
        if not os.path.exists('/var/log/screen-dreams'):
            os.makedirs('/var/log/screen-dreams', exist_ok=True)
        
        file_handler = RotatingFileHandler('/var/log/screen-dreams/app.log', maxBytes=10240000, backupCount=10)
        file_handler.setFormatter(logging.Formatter(
            '%(asctime)s %(levelname)s: %(message)s [in %(pathname)s:%(lineno)d]'
        ))
        file_handler.setLevel(logging.INFO)
        app.logger.addHandler(file_handler)
        app.logger.setLevel(logging.INFO)
        app.logger.info('Screen Dreams Screenwriter startup')
    
    # Register blueprints
    from app.routes import main
    app.register_blueprint(main)
    
    # Create database tables
    with app.app_context():
        db.create_all()
    
    return app
```

### 8. Monitoring and Health Checks

Add health check to `app/routes.py`:

```python
@main.route('/health')
def health_check():
    from datetime import datetime
    try:
        # Test database connection
        db.session.execute('SELECT 1')
        db_status = 'healthy'
    except:
        db_status = 'unhealthy'
    
    return {
        'status': 'healthy' if db_status == 'healthy' else 'unhealthy',
        'database': db_status,
        'timestamp': datetime.utcnow().isoformat(),
        'version': '1.0.0'
    }
```

### 9. Backup Strategy

Create backup script `/opt/screen-dreams/backup.sh`:

```bash
#!/bin/bash

BACKUP_DIR="/opt/backups/screen-dreams"
DATE=$(date +%Y%m%d_%H%M%S)
DB_FILE="/opt/screen-dreams/screenwriter.db"
SCREENPLAYS_DIR="/opt/screen-dreams/screenplays"

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Backup database
cp "$DB_FILE" "$BACKUP_DIR/screenwriter_$DATE.db"

# Backup screenplays
if [ -d "$SCREENPLAYS_DIR" ]; then
    tar -czf "$BACKUP_DIR/screenplays_$DATE.tar.gz" -C "$SCREENPLAYS_DIR" .
fi

# Clean old backups (keep 30 days)
find "$BACKUP_DIR" -name "*.db" -mtime +30 -delete
find "$BACKUP_DIR" -name "*.tar.gz" -mtime +30 -delete

echo "Backup completed: $DATE"
```

Add to crontab:
```bash
sudo crontab -e
# Add line for daily backup at 2 AM
0 2 * * * /opt/screen-dreams/backup.sh >> /var/log/screen-dreams/backup.log 2>&1
```

### 10. Scaling Considerations

For high-traffic deployments:

1. **Load Balancing**: Use multiple Gunicorn workers behind Nginx
2. **Database**: Migrate to PostgreSQL for better performance
3. **Caching**: Add Redis for session storage and caching
4. **CDN**: Use CloudFlare for static assets
5. **Monitoring**: Add Prometheus/Grafana for metrics
6. **Containerization**: Deploy with Docker/Kubernetes

Example Nginx upstream configuration:
```nginx
upstream screen_dreams_backend {
    server 127.0.0.1:8000;
    server 127.0.0.1:8001;
    server 127.0.0.1:8002;
}
```
