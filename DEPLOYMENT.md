# Awen Screenplay Editor - Deployment Guide

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
accesslog = "/var/log/screenplay-editor/access.log"
errorlog = "/var/log/screenplay-editor/error.log"
loglevel = "info"
access_log_format = '%(h)s %(l)s %(u)s %(t)s "%(r)s" %(s)s %(b)s "%(f)s" "%(a)s" %(D)s'

# Process naming
proc_name = "screenplay-editor"

# Server mechanics
daemon = False
pidfile = "/var/run/screenplay-editor/gunicorn.pid"
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

#### Linux (systemd)

Create `/etc/systemd/system/screenplay-editor.service`:

```ini
[Unit]
Description=Screenplay Editor Web Application
After=network.target
Wants=network.target

[Service]
Type=notify
User=www-data
Group=www-data
WorkingDirectory=/opt/screenplay-editor
Environment=PATH=/opt/screenplay-editor/venv/bin
EnvironmentFile=/opt/screenplay-editor/.env
ExecStart=/opt/screenplay-editor/venv/bin/gunicorn --config gunicorn.conf.py run:app
ExecReload=/bin/kill -s HUP $MAINPID
Restart=always
RestartSec=5
StartLimitInterval=60
StartLimitBurst=3

# Security
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=true
ReadWritePaths=/opt/screenplay-editor /var/log/screenplay-editor /var/run/screenplay-editor

[Install]
WantedBy=multi-user.target
```

```bash
# Create necessary directories and permissions
sudo mkdir -p /opt/screenplay-editor
sudo mkdir -p /var/log/screenplay-editor
sudo mkdir -p /var/run/screenplay-editor
sudo chown www-data:www-data /opt/screenplay-editor
sudo chown www-data:www-data /var/log/screenplay-editor
sudo chown www-data:www-data /var/run/screenplay-editor

# Enable and start service
sudo systemctl daemon-reload
sudo systemctl enable screenplay-editor
sudo systemctl start screenplay-editor
sudo systemctl status screenplay-editor
```

#### Windows (NSSM - Non-Sucking Service Manager)

```powershell
# Install NSSM
# Download from https://nssm.cc/download
# Extract and add to PATH

# Create service
nssm install ScreenplayEditor "C:\opt\screenplay-editor\venv\Scripts\gunicorn.exe"
nssm set ScreenplayEditor Arguments "--config gunicorn.conf.py run:app"
nssm set ScreenplayEditor Directory "C:\opt\screenplay-editor"
nssm set ScreenplayEditor DisplayName "Screenplay Editor"
nssm set ScreenplayEditor Description "Screenplay Editor Web Application"
nssm set ScreenplayEditor Start SERVICE_AUTO_START
nssm set ScreenplayEditor AppEnvironmentExtra "PYTHONPATH=C:\opt\screenplay-editor"

# Start service
nssm start ScreenplayEditor
```

#### macOS (launchd)

Create `/Library/LaunchDaemons/com.screenplay.editor.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.screenplay.editor</string>
    <key>ProgramArguments</key>
    <array>
        <string>/opt/screenplay-editor/venv/bin/gunicorn</string>
        <string>--config</string>
        <string>gunicorn.conf.py</string>
        <string>run:app</string>
    </array>
    <key>WorkingDirectory</key>
    <string>/opt/screenplay-editor</string>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/var/log/screenplay-editor/access.log</string>
    <key>StandardErrorPath</key>
    <string>/var/log/screenplay-editor/error.log</string>
    <key>UserName</key>
    <string>www</string>
    <key>GroupName</key>
    <string>www</string>
</dict>
</plist>
```

```bash
# Load and start service
sudo launchctl load /Library/LaunchDaemons/com.screenplay.editor.plist
sudo launchctl start com.screenplay.editor
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
    
    # Main Application (Proxy to Gunicorn)
    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header X-Forwarded-Host $host;
        proxy_set_header X-Forwarded-Port $server_port;
        
        # Timeouts
        proxy_connect_timeout 60s;
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;
        
        # Buffer sizes
        proxy_buffering on;
        proxy_buffer_size 4k;
        proxy_buffers 8 4k;
        proxy_busy_buffers_size 8k;
        
        # Headers
        proxy_redirect off;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";
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
sudo ln -s /etc/nginx/sites-available/screenplay-editor /etc/nginx/sites-enabled/
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

Create `/opt/screenplay-editor/.env`:

```bash
# Flask Configuration
FLASK_ENV=production
FLASK_DEBUG=False
SECRET_KEY=your-very-secure-secret-key-here-change-this-in-production

# Database
DATABASE_URL=sqlite:///screenwriter.db
# For PostgreSQL: postgresql://user:password@localhost/screenwriter

# Application Settings
SCREENPLAY_FOLDER=/opt/screenplay-editor/screenplays
MAX_CONTENT_LENGTH=16777216  # 16MB max upload

# AI Assistant (Ollama)
OLLAMA_BASE_URL=http://localhost:11434
OLLAMA_MODEL=llama2

# Logging
LOG_LEVEL=INFO
LOG_FILE=/var/log/screenplay-editor/app.log

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
        if not os.path.exists('/var/log/screenplay-editor'):
            os.makedirs('/var/log/screenplay-editor', exist_ok=True)
        
        file_handler = RotatingFileHandler('/var/log/screenplay-editor/app.log', maxBytes=10240000, backupCount=10)
        file_handler.setFormatter(logging.Formatter(
            '%(asctime)s %(levelname)s: %(message)s [in %(pathname)s:%(lineno)d]'
        ))
        file_handler.setLevel(logging.INFO)
        app.logger.addHandler(file_handler)
        app.logger.setLevel(logging.INFO)
        app.logger.info('Screenplay Editor startup')
    
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

Create backup script `/opt/screenplay-editor/backup.sh`:

```bash
#!/bin/bash

BACKUP_DIR="/opt/backups/screenplay-editor"
DATE=$(date +%Y%m%d_%H%M%S)
DB_FILE="/opt/screenplay-editor/screenwriter.db"
SCREENPLAYS_DIR="/opt/screenplay-editor/screenplays"

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
0 2 * * * /opt/screenplay-editor/backup.sh >> /var/log/screenplay-editor/backup.log 2>&1
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
upstream screenplay_backend {
    server 127.0.0.1:8000;
    server 127.0.0.1:8001;
    server 127.0.0.1:8002;
}
```
