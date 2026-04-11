#!/bin/bash
# Fixed Podman Deployment with Full Image Names
# Solves registry and permission issues

set -e

echo "=== Screen Dreams Fixed Podman Deployment ==="
echo "Fixed version with full image names and registry configuration"
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
    exit 1
fi

# Fix Podman registry configuration
print_header "Podman Configuration"

# Create registries.conf if it doesn't exist
if [ ! -f /etc/containers/registries.conf ]; then
    print_status "Creating Podman registry configuration..."
    sudo mkdir -p /etc/containers
    sudo tee /etc/containers/registries.conf > /dev/null << 'EOF'
[registries.search]
registries = ["docker.io"]

[registries.insecure]
registries = []

[registries.block]
registries = []
EOF
fi

# Set up unqualified search registries in user config
mkdir -p ~/.config/containers
cat > ~/.config/containers/registries.conf << 'EOF'
[registries.search]
registries = ["docker.io"]
EOF

print_status "Registry configuration updated"

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
print_status "Building with Alpine Linux image..."

podman build -t screen-dreams:lightweight -f Dockerfile.dev.podman .

# Create pod
print_status "Creating pod..."
podman pod create --name screen-dreams-pod \
    -p 5000:5000 \
    -p 80:80

# Start Redis with full image name
print_status "Starting Redis (Alpine)..."
podman run -d --name screen-dreams-redis-dev \
    --pod screen-dreams-pod \
    --restart unless-stopped \
    docker.io/library/redis:7-alpine

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
    localhost/screen-dreams:lightweight python3 run_dev.py

# Start nginx with full image name
print_status "Starting nginx (Alpine)..."
podman run -d --name screen-dreams-nginx-dev \
    --pod screen-dreams-pod \
    --restart unless-stopped \
    -v $(pwd)/docker/nginx/default.conf:/etc/nginx/conf.d/default.conf:ro \
    -v $(pwd)/static:/var/www/static:ro \
    docker.io/library/nginx:alpine

print_header "Health Check"

# Wait for services
sleep 15

# Check Redis
print_status "Checking Redis..."
if podman exec -it screen-dreams-redis-dev redis-cli ping >/dev/null 2>&1; then
    print_status "Redis is ready"
else
    print_warning "Redis might still be starting..."
fi

# Check application
print_status "Checking Flask application..."
if curl -f http://localhost:5000/health >/dev/null 2>&1; then
    print_status "Flask application is ready (port 5000)"
else
    print_warning "Flask application might still be starting..."
    print_status "Checking logs..."
    podman logs --tail=10 screen-dreams-dev
fi

# Check nginx
print_status "Checking nginx reverse proxy..."
if curl -f http://localhost/health >/dev/null 2>&1; then
    print_status "Nginx is ready (port 80)"
else
    print_warning "Nginx might still be starting..."
    print_status "Checking nginx logs..."
    podman logs --tail=10 screen-dreams-nginx-dev
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
print_status "Fixed deployment completed!"
echo
echo "Access:"
echo "  http://localhost (port 80)"
echo "  http://localhost:5000 (direct)"
echo
echo "Fixed issues:"
echo "  - Registry configuration for short names"
echo "  - Full image names (docker.io/library/...)"
echo "  - Lightweight Alpine images"

print_header "Troubleshooting"

echo "If you still get registry errors:"
echo "1. Use full image names: docker.io/library/redis:7-alpine"
echo "2. Check registry config: cat /etc/containers/registries.conf"
echo "3. Pull images manually: podman pull docker.io/library/redis:7-alpine"
echo
echo "Manual image pull commands:"
echo "  podman pull docker.io/library/redis:7-alpine"
echo "  podman pull docker.io/library/nginx:alpine"
