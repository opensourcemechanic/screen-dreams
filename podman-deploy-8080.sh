#!/bin/bash
# Podman Deployment with Port 8080 (Non-privileged)
# Avoids privileged port issues by using port 8080

set -e

echo "=== Screen Dreams Podman Deployment (Port 8080) ==="
echo "Using port 8080 to avoid privileged port restrictions"
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

# Clean up first
print_header "Cleanup"
print_status "Cleaning up existing containers..."
podman stop -a 2>/dev/null || true
podman rm -a 2>/dev/null || true
podman pod rm -a 2>/dev/null || true

# Build image
print_header "Build Application"
print_status "Building lightweight application image..."
podman build -t screen-dreams:lightweight -f Dockerfile.dev.podman .

# Create pod with port 8080
print_status "Creating pod with port 8080..."
podman pod create --name screen-dreams-pod \
    -p 5000:5000 \
    -p 8080:80

# Pull images first with full names
print_header "Pull Container Images"
print_status "Pulling Redis with full image name..."
podman pull docker.io/library/redis:7-alpine

print_status "Pulling nginx with full image name..."
podman pull docker.io/library/nginx:alpine

# Start Redis
print_header "Start Services"
print_status "Starting Redis..."
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

# Start nginx
print_status "Starting nginx..."
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

# Check nginx on port 8080
print_status "Checking nginx reverse proxy on port 8080..."
if curl -f http://localhost:8080/health >/dev/null 2>&1; then
    print_status "Nginx is ready (port 8080)"
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

echo
print_status "Port 8080 deployment completed!"
echo
echo "Access:"
echo "  http://localhost:8080 (nginx reverse proxy)"
echo "  http://localhost:5000 (direct Flask access)"
echo
echo "Note: Using port 8080 instead of 80 to avoid privileged port restrictions."

print_header "Port Forwarding Options"

echo "If you need port 80 access:"
echo "1. Use port forwarding:"
echo "   sudo iptables -t nat -A PREROUTING -p tcp --dport 80 -j REDIRECT --to-port 8080"
echo
echo "2. Or use reverse proxy:"
echo "   Install Apache/Nginx on host to proxy :80 to :8080"
echo
echo "3. Or fix sysctl and restart:"
echo "   sudo sysctl -w net.ipv4.ip_unprivileged_port_start=80"
echo "   sudo systemctl restart podman"
echo "   # Then redeploy with port 80"

print_header "Useful Commands"

echo "View logs:"
echo "  podman logs -f screen-dreams-dev"
echo "  podman logs -f screen-dreams-nginx-dev"
echo "  podman logs -f screen-dreams-redis-dev"
echo
echo "Restart services:"
echo "  podman restart screen-dreams-dev"
echo "  podman restart screen-dreams-nginx-dev"
echo
echo "Stop all services:"
echo "  podman stop -a"
echo "  podman rm -a"
echo "  podman pod rm screen-dreams-pod"
