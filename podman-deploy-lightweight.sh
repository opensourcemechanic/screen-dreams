#!/bin/bash
# Lightweight Podman Deployment for Low Disk Space
# Uses Alpine Linux image to minimize disk usage

set -e

echo "=== Screen Dreams Lightweight Podman Deployment ==="
echo "Optimized for low disk space environments"
echo

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}=== $1 ===${NC}"
}

# Check disk space
print_header "Disk Space Check"
AVAILABLE_SPACE=$(df . | tail -1 | awk '{print $4}')
AVAILABLE_GB=$((AVAILABLE_SPACE / 1024 / 1024))

print_status "Available disk space: ${AVAILABLE_GB}GB"

if [ "$AVAILABLE_GB" -lt 2 ]; then
    print_error "Insufficient disk space. Need at least 2GB free."
    echo "Current free space: ${AVAILABLE_GB}GB"
    echo
    echo "To free up space:"
    echo "1. sudo apt clean && sudo apt autoremove -y"
    echo "2. podman system prune -a -f"
    echo "3. rm -rf ~/.cache/pip"
    echo "4. Remove old container images: podman rmi -a"
    exit 1
fi

# Clean up first
print_header "Cleanup"
print_status "Cleaning up existing containers..."
podman stop -a 2>/dev/null || true
podman rm -a 2>/dev/null || true
podman pod rm -a 2>/dev/null || true

print_status "Cleaning Podman system cache..."
podman system prune -a -f

# Build with lightweight image
print_header "Lightweight Build"
print_status "Building with Alpine Linux image (smaller footprint)..."

podman build -t screen-dreams:lightweight -f Dockerfile.dev.podman .

# Create pod
print_status "Creating pod..."
podman pod create --name screen-dreams-pod \
    -p 5000:5000 \
    -p 80:80

# Start Redis (use Alpine image)
print_status "Starting Redis (Alpine)..."
podman run -d --name screen-dreams-redis-dev \
    --pod screen-dreams-pod \
    --restart unless-stopped \
    redis:7-alpine

# Start application
print_status "Starting application..."
podman run -d --name screen-dreams-dev \
    --pod screen-dreams-pod \
    --restart unless-stopped \
    -e DATABASE_URL=sqlite:///screenwriter_dev.db \
    -e REDIS_URL=redis://redis-dev:6379/0 \
    -e RATELIMIT_STORAGE_URL=redis://redis-dev:6379/0 \
    -e SECRET_KEY=dev-secret-key-change-in-production \
    -e AI_PROVIDER=ollama \
    -e OLLAMA_BASE_URL=http://ollama-dev:11434 \
    -e OLLAMA_MODEL=llama2 \
    -v $(pwd):/app \
    -v $(pwd)/uploads:/app/uploads \
    -v $(pwd)/screenplays:/app/screenplays \
    -v $(pwd)/logs:/var/log/screen-dreams \
    screen-dreams:lightweight python3 run_dev.py

# Start nginx (use Alpine image)
print_status "Starting nginx (Alpine)..."
podman run -d --name screen-dreams-nginx-dev \
    --pod screen-dreams-pod \
    --restart unless-stopped \
    -v $(pwd)/docker/nginx/default.conf:/etc/nginx/conf.d/default.conf:ro \
    -v $(pwd)/static:/var/www/static:ro \
    nginx:alpine

print_header "Health Check"

# Wait for services
sleep 15

# Check application
if curl -f http://localhost:5000/health >/dev/null 2>&1; then
    print_status "Application is ready (port 5000)"
else
    print_warning "Application might still be starting..."
fi

# Check nginx
if curl -f http://localhost/health >/dev/null 2>&1; then
    print_status "Nginx is ready (port 80)"
else
    print_warning "Nginx might still be starting..."
fi

print_header "Deployment Summary"

# Show containers
print_status "Running containers:"
podman ps

# Show disk usage
print_status "Disk usage:"
df -h .

# Show image sizes
print_status "Container image sizes:"
podman images | head -5

echo
print_status "Lightweight deployment completed!"
echo
echo "Access:"
echo "  http://localhost (port 80)"
echo "  http://localhost:5000 (direct)"
echo
echo "Disk space saved by using Alpine images!"

print_header "Space Saving Tips"

echo "To further save space:"
echo "1. Remove build cache: podman builder prune -a"
echo "2. Remove unused images: podman rmi -a"
echo "3. Clean logs: podman logs --tail 0"
echo "4. Use volumes instead of bind mounts where possible"
