#!/bin/bash
# Podman Deployment Script for Screen Dreams
# Optimized for Podman container engine (Docker alternative)

set -e

echo "=== Screen Dreams Podman Deployment ==="
echo "This script deploys Screen Dreams with nginx port 80 access using Podman"
echo

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
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

# Check if running as root (not recommended for Podman)
if [ "$EUID" -eq 0 ]; then
    print_warning "Running as root is not recommended for Podman. Consider using a regular user."
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

print_header "System Check"

# Check Podman
print_status "Checking Podman installation..."
if ! command -v podman >/dev/null 2>&1; then
    print_error "Podman is not installed. Please install Podman first."
    echo "Visit: https://podman.io/docs/installation"
    exit 1
fi

print_status "Podman found: $(podman --version | head -1)"

# Check available memory
print_status "Checking system resources..."
TOTAL_MEM=$(free -m | awk 'NR==2{print $2}')
if [ "$TOTAL_MEM" -lt 2048 ]; then
    print_warning "Low memory detected (${TOTAL_MEM}MB). 2GB+ recommended for optimal performance."
fi

# Check disk space
DISK_SPACE=$(df . | tail -1 | awk '{print $4}')
if [ "$DISK_SPACE" -lt 10485760 ]; then  # 10GB in KB
    print_warning "Low disk space detected. 10GB+ recommended."
fi

print_header "Environment Setup"

# Create necessary directories
print_status "Creating directories..."
mkdir -p logs uploads screenplays docker/ssl

# Check if we're in the right directory
if [ ! -f "docker-compose.dev.yml" ]; then
    print_error "docker-compose.dev.yml not found. Please run this script from the screen-dreams root directory."
    exit 1
fi

# Setup environment file
if [ ! -f .env ]; then
    print_status "Creating .env file from template..."
    cp .env.docker .env
    print_warning "Please edit .env file with your configuration."
    print_warning "Especially set SECRET_KEY and AI provider credentials."
    
    # Show what needs to be configured
    echo
    print_status "Important settings to configure in .env:"
    echo "  - SECRET_KEY (change from default)"
    echo "  - AI_PROVIDER (ollama, openai, anthropic)"
    echo "  - OPENAI_API_KEY (if using OpenAI)"
    echo "  - ANTHROPIC_API_KEY (if using Anthropic)"
    echo
    
    read -p "Press Enter to continue (will edit .env after deployment)..."
fi

print_header "Port Check"

# Check if ports are available
print_status "Checking port availability..."

if netstat -tln 2>/dev/null | grep -q ":80 "; then
    print_warning "Port 80 is already in use."
    echo "This might conflict with nginx. Common conflicts:"
    echo "  - Apache web server"
    echo "  - Another nginx instance"
    echo "  - System web service"
    echo
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

if netstat -tln 2>/dev/null | grep -q ":5000 "; then
    print_warning "Port 5000 is already in use."
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

print_header "Podman Deployment"

# Stop and remove existing containers/pods
print_status "Cleaning up existing containers..."
podman stop screen-dreams-dev screen-dreams-nginx-dev screen-dreams-redis-dev 2>/dev/null || true
podman rm screen-dreams-dev screen-dreams-nginx-dev screen-dreams-redis-dev 2>/dev/null || true
podman pod rm screen-dreams-pod 2>/dev/null || true

# Remove orphaned containers
print_status "Cleaning up orphaned containers..."
podman pod prune -f >/dev/null 2>&1 || true

# Create pod for networking
print_status "Creating pod for container networking..."
podman pod create --name screen-dreams-pod \
    -p 5000:5000 \
    -p 80:80 \
    --share net,ipc,uts

# Build image
print_status "Building Screen Dreams image..."
podman build -t screen-dreams:dev -f Dockerfile.dev .

# Start Redis container
print_status "Starting Redis container..."
podman run -d --name screen-dreams-redis-dev \
    --pod screen-dreams-pod \
    --restart unless-stopped \
    redis:7-alpine

# Start main application container
print_status "Starting Screen Dreams application..."
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
    screen-dreams:dev python3 run_dev.py

# Start nginx container
print_status "Starting nginx reverse proxy..."
podman run -d --name screen-dreams-nginx-dev \
    --pod screen-dreams-pod \
    --restart unless-stopped \
    -v $(pwd)/docker/nginx/default.conf:/etc/nginx/conf.d/default.conf:ro \
    -v $(pwd)/static:/var/www/static:ro \
    nginx:alpine

print_header "Service Health Check"

# Wait for services to start
print_status "Waiting for services to initialize..."
sleep 20

# Check Redis
print_status "Checking Redis..."
if podman exec -it screen-dreams-redis-dev redis-cli ping >/dev/null 2>&1; then
    print_status "Redis is ready"
else
    print_warning "Redis might still be starting..."
fi

# Check main application
print_status "Checking Flask application..."
sleep 10
if curl -f http://localhost:5000/health >/dev/null 2>&1; then
    print_status "Flask application is ready (port 5000)"
else
    print_warning "Flask application might still be starting..."
    print_status "Checking logs..."
    podman logs --tail=10 screen-dreams-dev
fi

# Check nginx
print_status "Checking nginx reverse proxy..."
sleep 5
if curl -f http://localhost/health >/dev/null 2>&1; then
    print_status "Nginx reverse proxy is ready (port 80)"
else
    print_warning "Nginx might still be starting..."
    print_status "Checking nginx logs..."
    podman logs --tail=10 screen-dreams-nginx-dev
fi

print_header "Deployment Summary"

# Show running containers
print_status "Running containers:"
podman ps

# Show pod information
print_status "Pod information:"
podman pod ls

echo
print_status "Deployment completed!"
echo

print_header "Access Information"

echo "Primary Access (Recommended):"
echo "  URL: http://localhost"
echo "  Port: 80 (nginx reverse proxy)"
echo
echo "Direct Access:"
echo "  URL: http://localhost:5000"
echo "  Port: 5000 (Flask app)"
echo
echo "Health Checks:"
echo "  Nginx: http://localhost/health"
echo "  Direct: http://localhost:5000/health"

print_header "Next Steps"

echo "1. Configure AI services:"
echo "   - Edit .env file for your AI provider"
echo "   - For local AI: podman run -d --name ollama-dev --pod screen-dreams-pod ollama/ollama"
echo "   - Then: podman exec ollama-dev ollama pull llama2"
echo
echo "2. Test the application:"
echo "   - Open http://localhost in your browser"
echo "   - Create a screenplay and test AI features"
echo
echo "3. For production:"
echo "   - Change SECRET_KEY in .env"
echo "   - Set up HTTPS/SSL"
echo "   - Configure firewall rules"
echo
echo "4. Enable auto-start (optional):"
echo "   podman generate systemd --name screen-dreams-pod"
echo "   cp container-*service /etc/systemd/system/"
echo "   systemctl enable container-screen-dreams-pod.service"

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
echo
echo "Access Redis:"
echo "  podman exec -it screen-dreams-redis-dev redis-cli"

print_header "Troubleshooting"

echo "If services don't start:"
echo "1. Check logs: podman logs [container-name]"
echo "2. Verify ports: netstat -tlnp | grep -E ':(80|5000)'"
echo "3. Check containers: podman ps"
echo "4. Restart: podman restart [container-name]"
echo
echo "For port conflicts:"
echo "1. Stop conflicting services: sudo systemctl stop apache2 nginx"
echo "2. Or change ports in podman run commands"
echo
echo "Podman-specific issues:"
echo "1. Check pod status: podman pod ls"
echo "2. Check pod networking: podman exec -it screen-dreams-dev ping redis-dev"
echo "3. Verify image: podman images"

echo
print_status "Thank you for deploying Screen Dreams with Podman!"
print_status "For more help, see PODMAN-DEPLOYMENT.md"
