# Podman Deployment Guide

## Deploy Screen Dreams with Podman (Docker Alternative)

### Understanding Podman vs Docker
- **Podman**: Daemonless container engine (what you have)
- **Docker**: Traditional container daemon (what scripts expect)
- **Compatibility**: Podman can run most Docker containers
- **Commands**: Mostly the same, but some differences

## Quick Fix: Use Podman Directly

### Option 1: Use Podman Commands (Recommended)

```bash
# Navigate to project
cd /path/to/screen-dreams

# Set up environment
cp .env.docker .env
nano .env  # Edit with your values

# Build image with Podman
podman build -t screen-dreams:dev -f Dockerfile.dev .

# Run containers with Podman
podman run -d --name screen-dreams-redis-dev \
  -p 6379:6379 \
  redis:7-alpine

podman run -d --name screen-dreams-dev \
  -p 5000:5000 \
  -e DATABASE_URL=sqlite:///screen_dreams.db \
  -e SECRET_KEY=your-secret-key \
  -e AI_PROVIDER=ollama \
  -v $(pwd):/app \
  --pod screen-dreams-pod \
  screen-dreams:dev python3 run_dev.py

podman run -d --name screen-dreams-nginx-dev \
  -p 80:80 \
  -v $(pwd)/docker/nginx/default.conf:/etc/nginx/conf.d/default.conf \
  --pod screen-dreams-pod \
  nginx:alpine
```

### Option 2: Install Docker Compose Alternative

```bash
# Install Podman Compose
pip3 install podman-compose

# Or use system package manager
sudo apt install -y podman-compose

# Then run deployment
podman-compose -f docker-compose.dev.yml up -d
```

### Option 3: Create Docker Alias (Simple)

```bash
# Add to ~/.bashrc
echo 'alias docker=podman' >> ~/.bashrc
echo 'alias docker-compose=podman-compose' >> ~/.bashrc
source ~/.bashrc

# Now use original commands
docker-compose -f docker-compose.dev.yml up -d
```

## Podman-Specific Deployment Script

### Create podman-deploy.sh

```bash
#!/bin/bash
# Podman deployment script for Screen Dreams

set -e

echo "=== Screen Dreams Podman Deployment ==="

# Check Podman
if ! command -v podman >/dev/null 2>&1; then
    echo "ERROR: Podman not found"
    exit 1
fi

# Create pod for networking
echo "Creating pod..."
podman pod create --name screen-dreams-pod -p 5000:5000 -p 80:80

# Build image
echo "Building image..."
podman build -t screen-dreams:dev -f Dockerfile.dev .

# Start Redis
echo "Starting Redis..."
podman run -d --name screen-dreams-redis-dev \
  --pod screen-dreams-pod \
  redis:7-alpine

# Start application
echo "Starting application..."
podman run -d --name screen-dreams-dev \
  --pod screen-dreams-pod \
  -e DATABASE_URL=sqlite:///screen_dreams.db \
  -e SECRET_KEY=your-secret-key \
  -e AI_PROVIDER=ollama \
  -v $(pwd):/app \
  screen-dreams:dev python3 run_dev.py

# Start nginx
echo "Starting nginx..."
podman run -d --name screen-dreams-nginx-dev \
  --pod screen-dreams-pod \
  -v $(pwd)/docker/nginx/default.conf:/etc/nginx/conf.d/default.conf \
  nginx:alpine

echo "Deployment completed!"
echo "Access: http://localhost"
```

## Fix Docker Compose for Podman

### Install Podman Compose

```bash
# Method 1: pip
pip3 install podman-compose

# Method 2: System package (Ubuntu/Debian)
sudo apt update
sudo apt install -y podman-compose

# Method 3: Direct download
curl -L "https://github.com/containers/podman-compose/releases/latest/download/podman-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/podman-compose
chmod +x /usr/local/bin/podman-compose
```

### Use Existing Scripts

```bash
# After installing podman-compose
podman-compose -f docker-compose.dev.yml up -d

# Or with alias
alias docker-compose=podman-compose
./deploy-docker-simple.sh
```

## Environment Setup

### Create .env file

```bash
cp .env.docker .env
nano .env
```

**Required settings:**
```bash
SECRET_KEY=your-secret-key-here
AI_PROVIDER=ollama
OLLAMA_BASE_URL=http://ollama-dev:11434
OLLAMA_MODEL=llama2
```

## Podman-Specific Considerations

### Networking
- **Pods**: Use pods for container networking (better than links)
- **Ports**: Port mapping works differently
- **DNS**: Containers can communicate by service name

### Volumes
- **Bind mounts**: Work the same as Docker
- **Named volumes**: Use `podman volume` commands

### Systemd Integration
```bash
# Generate systemd service
podman generate systemd --name screen-dreams-pod

# Enable auto-start
cp container-*service /etc/systemd/system/
systemctl enable container-screen-dreams-pod.service
systemctl start container-screen-dreams-pod.service
```

## Troubleshooting

### Common Issues

```bash
# Check if podman is working
podman --version
podman ps

# Check pods
podman pod ls

# Check logs
podman logs screen-dreams-dev

# Clean up
podman stop -a
podman rm -a
podman pod rm screen-dreams-pod
```

### Permission Issues
```bash
# Podman doesn't need docker group
# No sudo required for regular users
# Rootless containers work out of the box
```

### Docker Compose Compatibility
```bash
# If podman-compose doesn't work
# Try the alias method
alias docker=podman
alias docker-compose=podman-compose

# Or use podman directly
podman-compose -f docker-compose.dev.yml up -d
```

## Quick Start Commands

```bash
# 1. Install podman-compose
pip3 install podman-compose

# 2. Set up environment
cp .env.docker .env
nano .env

# 3. Deploy
podman-compose -f docker-compose.dev.yml up -d

# 4. Check status
podman ps
podman pod ls
```

## Next Steps

1. **Choose deployment method** (alias vs podman-compose vs direct)
2. **Set up environment variables**
3. **Run deployment**
4. **Test access** (http://localhost)
5. **Set up systemd** for auto-start if needed

Podman will work perfectly for Screen Dreams once you use the right commands!
