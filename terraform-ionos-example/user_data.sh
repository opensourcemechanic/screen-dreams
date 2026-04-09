#!/bin/bash
set -e

# Update system
apt-get update -y
apt-get upgrade -y

# Install Docker
apt-get install -y apt-transport-https ca-certificates curl software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Start and enable Docker
systemctl start docker
systemctl enable docker
usermod -a -G docker ubuntu

# Create application directories
mkdir -p /opt/screen-dreams
cd /opt/screen-dreams

# Clone the repository
git clone https://github.com/opensourcemechanic/screen-dreams.git .
chown -R ubuntu:ubuntu /opt/screen-dreams

# Create environment file
cat > .env << EOF
# Database Configuration
DATABASE_URL=postgresql://${db_username}:${db_password}@${db_endpoint}:${db_port}/${db_name}

# AI Provider Configuration
AI_PROVIDER=${ai_provider}
IONOS_API_KEY=${ionos_api_key}
OPENAI_API_KEY=${openai_api_key}
ANTHROPIC_API_KEY=${anthropic_api_key}

# Flask Configuration
SECRET_KEY=${secret_key}
FLASK_ENV=production
FLASK_DEBUG=False

# File Upload Configuration
UPLOAD_FOLDER=/opt/screen-dreams/uploads
MAX_CONTENT_LENGTH=104857600

# AWS S3 Configuration (using IONOS S3)
AWS_S3_BUCKET=${s3_bucket}
AWS_DEFAULT_REGION=eu-central-1
AWS_ACCESS_KEY_ID=your-ionos-s3-key
AWS_SECRET_ACCESS_KEY=your-ionos-s3-secret

# Rate Limiting (using in-memory since no Redis)
RATELIMIT_STORAGE_URL=memory://

# Logging Configuration
LOG_LEVEL=INFO

# Security Configuration
SESSION_COOKIE_SECURE=False
SESSION_COOKIE_HTTPONLY=True
SESSION_COOKIE_SAMESITE=Lax

# Content Security Policy
CSP_DEFAULT_SRC="'self'"
CSP_SCRIPT_SRC="'self' 'unsafe-inline'"
CSP_STYLE_SRC="'self' 'unsafe-inline'"
CSP_IMG_SRC="'self' data:"
CSP_FONT_SRC="'self'"

# Email Settings
SECURITY_EMAIL_SENDER=noreply@screendreams.com
EOF

# Create necessary directories
mkdir -p uploads screenplays logs

# Set permissions
chown -R ubuntu:ubuntu /opt/screen-dreams

# Deploy the application
cd /opt/screen-dreams
sudo -u ubuntu /usr/local/bin/docker-compose -f docker-compose.yml up -d

# Wait for services to start
sleep 30

# Check if services are running
echo "Checking service status..."
sudo -u ubuntu /usr/local/bin/docker-compose ps

# Create a simple health check script
cat > /home/ubuntu/health-check.sh << 'EOF'
#!/bin/bash
echo "=== Screen Dreams Health Check ==="
echo "Application Status:"
curl -s http://localhost:5000/ | head -5 || echo "Application not responding"
echo ""
echo "Docker Services:"
docker-compose ps
echo ""
echo "System Resources:"
free -h
echo ""
echo "Disk Usage:"
df -h
EOF

chmod +x /home/ubuntu/health-check.sh
chown ubuntu:ubuntu /home/ubuntu/health-check.sh

# Create a simple update script
cat > /home/ubuntu/update-app.sh << 'EOF'
#!/bin/bash
cd /opt/screen-dreams
echo "Updating Screen Dreams application..."
git pull origin main
docker-compose down
docker-compose up -d --build
echo "Update completed!"
EOF

chmod +x /home/ubuntu/update-app.sh
chown ubuntu:ubuntu /home/ubuntu/update-app.sh

echo "Screen Dreams deployment on IONOS completed!"
echo "Access the application at: http://$(curl -s http://ipinfo.io/ip)"
echo "Run './health-check.sh' to check application status"
echo "Run './update-app.sh' to update the application"
