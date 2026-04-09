#!/bin/bash
set -e

# Log everything to a file for debugging
exec > >(tee /var/log/user-data.log)
exec 2>&1

echo "=== Screen Dreams Deployment Started at $(date) ==="

# Update system
echo "Updating system packages..."
yum update -y

# Install Docker
yum install -y docker
systemctl start docker
systemctl enable docker
usermod -a -G docker ec2-user

# Install Docker Compose
curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Install unzip for extracting app files
echo "Installing unzip..."
yum install -y unzip

# Create application directory
echo "Creating application directory..."
mkdir -p /opt/screen-dreams
cd /opt/screen-dreams

# Download and extract application files from S3 FIRST
echo "=== Downloading application files from S3 ==="
echo "S3 Bucket: ${s3_bucket}"
echo "S3 Key: ${app_deployment_s3_key}"
echo "Downloading to: /tmp/app-deployment.zip"

if aws s3 cp s3://${s3_bucket}/${app_deployment_s3_key} /tmp/app-deployment.zip; then
  echo "✓ Download successful"
  ls -lh /tmp/app-deployment.zip
else
  echo "✗ ERROR: Failed to download from S3"
  echo "Checking S3 bucket contents..."
  aws s3 ls s3://${s3_bucket}/deployments/ || echo "Failed to list S3 bucket"
  exit 1
fi

echo "=== Extracting application files ==="
if unzip -o /tmp/app-deployment.zip -d /opt/screen-dreams/; then
  echo "✓ Extraction successful"
else
  echo "✗ ERROR: Failed to extract ZIP file"
  exit 1
fi

echo "Cleaning up ZIP file..."
rm /tmp/app-deployment.zip

# Create necessary directories
echo "Creating additional directories..."
mkdir -p uploads screenplays logs

# Create Docker startup script for direct container deployment
cat > /home/ec2-user/start-screen-dreams.sh << 'EOF'
#!/bin/bash

# Stop and remove existing containers if they exist
docker stop screen-dreams nginx ollama 2>/dev/null || true
docker rm screen-dreams nginx ollama 2>/dev/null || true

# Start Ollama container if AI provider is ollama
if [ "${ai_provider}" = "ollama" ]; then
  echo "Starting Ollama container..."
  docker run -d \
    --name ollama \
    --restart unless-stopped \
    -p 11434:11434 \
    -v ollama:/root/.ollama \
    ollama/ollama:latest
  
  # Wait for Ollama to start
  echo "Waiting for Ollama to start..."
  sleep 10
  
  # Pull the specified model
  echo "Pulling Ollama model: ${ollama_model}"
  docker exec ollama ollama pull ${ollama_model}
  
  # Verify Ollama is running
  if docker ps | grep ollama; then
    echo "Ollama container started successfully!"
  else
    echo "ERROR: Failed to start Ollama container"
  fi
fi

# Run the screen-dreams container directly
# Use host networking when using Ollama for reliable communication
if [ "${ai_provider}" = "ollama" ]; then
  NETWORK_MODE="--network host"
  PORT_MAPPING=""
else
  NETWORK_MODE=""
  PORT_MAPPING="-p 5000:5000"
fi

docker run -d \
  --name screen-dreams \
  --restart unless-stopped \
  $PORT_MAPPING \
  $NETWORK_MODE \
  -e DATABASE_TYPE=sqlite \
  -e DATABASE_URL=sqlite:///opt/screen-dreams/screen_dreams.db \
  -e SECRET_KEY=${secret_key} \
  -e AI_PROVIDER=${ai_provider} \
  -e OPENAI_API_KEY=${openai_api_key} \
  -e ANTHROPIC_API_KEY=${anthropic_api_key} \
  -e IONOS_API_KEY=${ionos_api_key} \
  -e SCALEWAY_API_KEY=${scaleway_api_key} \
  -e OLLAMA_BASE_URL=${ollama_base_url} \
  -e OLLAMA_MODEL=${ollama_model} \
  -e OLLAMA_API_KEY=${ollama_api_key} \
  -e FLASK_ENV=production \
  -e FLASK_DEBUG=False \
  -e UPLOAD_FOLDER=/opt/screen-dreams/uploads \
  -e MAX_CONTENT_LENGTH=104857600 \
  -e AWS_S3_BUCKET=${s3_bucket} \
  -e AWS_DEFAULT_REGION=us-east-1 \
  -e RATELIMIT_STORAGE_URL=memory:// \
  -e LOG_LEVEL=INFO \
  -e SESSION_COOKIE_SECURE=False \
  -e SESSION_COOKIE_HTTPONLY=True \
  -e SESSION_COOKIE_SAMESITE=Lax \
  -e CSP_DEFAULT_SRC="'self'" \
  -e CSP_SCRIPT_SRC="'self' 'unsafe-inline'" \
  -e CSP_STYLE_SRC="'self' 'unsafe-inline'" \
  -e CSP_IMG_SRC="'self' data:" \
  -e CSP_FONT_SRC="'self'" \
  -e SECURITY_EMAIL_SENDER=noreply@screendreams.com \
  -v /opt/screen-dreams/uploads:/opt/screen-dreams/uploads \
  -v /opt/screen-dreams/screenplays:/opt/screen-dreams/screenplays \
  -v /opt/screen-dreams/logs:/opt/screen-dreams/logs \
  screen-dreams:latest

# Start nginx reverse proxy for port 80 access
# Update nginx config for host networking if using Ollama
if [ "${ai_provider}" = "ollama" ]; then
  # Update nginx config to use localhost for host networking
  cat > nginx.conf << NGINXEOF
events {
    worker_connections 1024;
}

http {
    upstream screen_dreams {
        server localhost:5000;
    }

    server {
        listen 80;
        location / {
            proxy_pass http://localhost:5000;
            proxy_set_header Host \$host;
            proxy_set_header X-Real-IP \$remote_addr;
            proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto \$scheme;
        }
    }
}
NGINXEOF
  
  # Start nginx without linking (using host network)
  docker run -d \
    --name nginx \
    --restart unless-stopped \
    -p 80:80 \
    -v /opt/screen-dreams/nginx.conf:/etc/nginx/nginx.conf:ro \
    nginx:alpine
else
  # Start nginx with container linking for other AI providers
  docker run -d \
    --name nginx \
    --restart unless-stopped \
    -p 80:80 \
    -v /opt/screen-dreams/nginx.conf:/etc/nginx/nginx.conf:ro \
    --link screen-dreams:screen-dreams \
    nginx:alpine
fi

echo "Screen Dreams and nginx containers started successfully!"
docker ps | grep -E "(screen-dreams|nginx)"
EOF

chmod +x /home/ec2-user/start-screen-dreams.sh
chown ec2-user:ec2-user /home/ec2-user/start-screen-dreams.sh

# Create nginx.conf
cat > nginx.conf << 'EOF'
events {
    worker_connections 1024;
}

http {
    upstream screen_dreams {
        server screen-dreams:5000;
    }

    server {
        listen 80;
        server_name localhost;

        location / {
            proxy_pass http://screen_dreams;
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
        }
    }
}
EOF

# Verify app files were extracted
echo "Verifying app files..."
ls -la /opt/screen-dreams/

if [ ! -f "/opt/screen-dreams/Dockerfile" ]; then
  echo "ERROR: Dockerfile not found after extraction!"
  exit 1
fi

chown -R ec2-user:ec2-user /opt/screen-dreams

# Create environment file
cat > .env << EOF
# Database Configuration
DATABASE_TYPE=${database_type}
EOF

# Add database-specific configuration
if [ "${database_type}" = "postgres" ]; then
  cat >> .env << EOF
DATABASE_URL=postgresql://${db_username}:${db_password}@${db_endpoint}:${db_port}/${db_name}
EOF
elif [ "${database_type}" = "dynamodb" ]; then
  cat >> .env << EOF
DYNAMODB_REGION=${region}
DYNAMODB_USERS_TABLE=${app_name}-users
DYNAMODB_SCREENPLAYS_TABLE=${app_name}-screenplays
DYNAMODB_SCENES_TABLE=${app_name}-scenes
EOF
elif [ "${database_type}" = "sqlite" ]; then
  cat >> .env << EOF
DATABASE_URL=sqlite:///opt/screen-dreams/screen_dreams.db
SQLITE_BACKUP_BUCKET=${sqlite_backup_bucket}
EOF
fi

# AI Provider Configuration
cat >> .env << EOF
AI_PROVIDER=${ai_provider}
OPENAI_API_KEY=${openai_api_key}
ANTHROPIC_API_KEY=${anthropic_api_key}
IONOS_API_KEY=${ionos_api_key}
SCALEWAY_API_KEY=${scaleway_api_key}

# Ollama Configuration
OLLAMA_BASE_URL=${ollama_base_url}
OLLAMA_MODEL=${ollama_model}
OLLAMA_API_KEY=${ollama_api_key}

# Flask Configuration
SECRET_KEY=${secret_key}
FLASK_ENV=production
FLASK_DEBUG=False

# File Upload Configuration
UPLOAD_FOLDER=/opt/screen-dreams/uploads
MAX_CONTENT_LENGTH=104857600

# AWS S3 Configuration
AWS_S3_BUCKET=${s3_bucket}
AWS_DEFAULT_REGION=us-east-1

# Rate Limiting (using in-memory since no Redis)
RATELIMIT_STORAGE_URL=memory://

# Logging Configuration
LOG_LEVEL=INFO
EOF

# Security Configuration
cat >> .env << EOF
SESSION_COOKIE_SECURE=False
SESSION_COOKIE_HTTPONLY=True
SESSION_COOKIE_SAMESITE=Lax

# Email Settings
SECURITY_EMAIL_SENDER=noreply@screendreams.com
EOF

# Create necessary directories
mkdir -p uploads screenplays logs

# Set permissions
chown -R ec2-user:ec2-user /opt/screen-dreams

# Deploy the application using direct container deployment
cd /opt/screen-dreams

# Build Docker image first
echo "Building Docker image..."
sudo docker build -t screen-dreams:latest .

# Verify image was built successfully
if sudo docker images | grep screen-dreams; then
  echo "Docker image built successfully!"
  echo "Starting Screen Dreams container..."
  sudo -u ec2-user /home/ec2-user/start-screen-dreams.sh
else
  echo "ERROR: Docker image build failed"
  exit 1
fi

# Wait for container to start
sleep 30

# Check if container is running
echo "Checking container status..."
sudo docker ps | grep screen-dreams

# Create a simple health check script
cat > /home/ec2-user/health-check.sh << 'EOF'
#!/bin/bash
echo "=== Screen Dreams Health Check ==="
echo "Application Status (Port 5000):"
curl -s http://localhost:5000/health || echo "Application not responding on port 5000"
echo ""
echo "Application Status (Port 80):"
curl -s http://localhost:80/health || echo "Application not responding on port 80"
echo ""
echo "Docker Containers:"
docker ps | grep -E "(screen-dreams|nginx|ollama)" || echo "Containers not running"
echo ""
echo "Screen Dreams Logs:"
docker logs --tail 5 screen-dreams 2>/dev/null || echo "No logs available"
echo ""
echo "Nginx Logs:"
docker logs --tail 5 nginx 2>/dev/null || echo "No nginx logs available"
echo ""
echo "Ollama Status:"
curl -s http://localhost:11434/api/tags 2>/dev/null | jq -r '.models[].name' || echo "Ollama not responding on port 11434"
echo ""
echo "System Resources:"
free -h
echo ""
echo "Disk Usage:"
df -h
EOF

chmod +x /home/ec2-user/health-check.sh
chown ec2-user:ec2-user /home/ec2-user/health-check.sh

# Create a simple update script
cat > /home/ec2-user/update-app.sh << 'EOF'
#!/bin/bash
cd /opt/screen-dreams
echo "Updating Screen Dreams application..."
git pull origin main

# Rebuild and restart container
docker stop screen-dreams 2>/dev/null || true
docker rm screen-dreams 2>/dev/null || true
docker build -t screen-dreams:latest .

# Start updated container
/home/ec2-user/start-screen-dreams.sh
echo "Update completed!"
EOF

chmod +x /home/ec2-user/update-app.sh
chown ec2-user:ec2-user /home/ec2-user/update-app.sh

# Build Docker image from downloaded files (moved to deployment section above)

# Create systemd service for automatic Docker startup
cat > /etc/systemd/system/screen-dreams.service << 'EOF'
[Unit]
Description=Screen Dreams and Nginx Containers
After=docker.service
Requires=docker.service

[Service]
Type=oneshot
RemainAfterExit=yes
WorkingDirectory=/opt/screen-dreams
ExecStart=/home/ec2-user/start-screen-dreams.sh
ExecStop=/usr/bin/docker stop screen-dreams nginx
ExecStopPost=/usr/bin/docker rm screen-dreams nginx
TimeoutStartSec=0

[Install]
WantedBy=multi-user.target
EOF

# Enable and start the service
systemctl enable screen-dreams.service
systemctl start screen-dreams.service

# Wait a moment for services to start
sleep 30

# Check if services are running
echo "Checking Docker services status..."
docker-compose ps

echo "Screen Dreams deployment completed!"
echo "Access the application at: http://$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)"
echo "Run './health-check.sh' to check application status"
echo "Run './update-app.sh' to update the application"
echo "Docker services will automatically start on reboot"
