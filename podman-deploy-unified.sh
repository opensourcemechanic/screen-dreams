#!/bin/bash
# Unified Podman Deployment Script for Screen Dreams
# Supports multiple deployment modes and registry configurations

set -e

echo "=== Screen Dreams Unified Podman Deployment ==="
echo "Flexible deployment with registry and port options"
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

# Default configuration
USE_PORT_8080=true
USE_FULL_IMAGE_NAMES=false
USE_REGISTRY_CONFIG=true
LIGHTWEIGHT_BUILD=true

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --port-80)
            USE_PORT_8080=false
            shift
            ;;
        --port-8080)
            USE_PORT_8080=true
            shift
            ;;
        --full-image-names)
            USE_FULL_IMAGE_NAMES=true
            shift
            ;;
        --no-registry-config)
            USE_REGISTRY_CONFIG=false
            shift
            ;;
        --lightweight)
            LIGHTWEIGHT_BUILD=true
            shift
            ;;
        --standard-build)
            LIGHTWEIGHT_BUILD=false
            shift
            ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo
            echo "Options:"
            echo "  --port-80           Use port 80 (requires sudo/privileged)"
            echo "  --port-8080         Use port 8080 (default, avoids privileged ports)"
            echo "  --full-image-names  Use full image names (docker.io/library/...)"
            echo "  --no-registry-config Skip registry configuration"
            echo "  --lightweight       Use Alpine Linux build (default)"
            echo "  --standard-build    Use standard Debian build"
            echo "  --help              Show this help message"
            echo
            echo "Examples:"
            echo "  $0                           # Default: port 8080, lightweight, auto-registry"
            echo "  $0 --port-80 --full-image-names  # Port 80, full names, no registry config"
            echo "  $0 --no-registry-config            # Skip registry setup"
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Display configuration
print_header "Deployment Configuration"
echo "Port 8080: $USE_PORT_8080"
echo "Full Image Names: $USE_FULL_IMAGE_NAMES"
echo "Registry Config: $USE_REGISTRY_CONFIG"
echo "Lightweight Build: $LIGHTWEIGHT_BUILD"
echo

# Check if running as root
if [ "$EUID" -eq 0 ]; then
    print_warning "Running as root is not recommended for Podman."
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
    exit 1
fi

print_status "Podman found: $(podman --version | head -1)"

# Check available memory
print_status "Checking system resources..."
TOTAL_MEM=$(free -m | awk 'NR==2{print $2}')
if [ "$TOTAL_MEM" -lt 2048 ]; then
    print_warning "Low memory detected (${TOTAL_MEM}MB). 2GB+ recommended."
fi

# Check disk space
DISK_SPACE=$(df . | tail -1 | awk '{print $4}')
if [ "$DISK_SPACE" -lt 10485760 ]; then  # 10GB in KB
    print_warning "Low disk space detected. 10GB+ recommended."
fi

# Registry configuration
if [ "$USE_REGISTRY_CONFIG" = true ] && [ "$USE_FULL_IMAGE_NAMES" = false ]; then
    print_header "Podman Registry Configuration"
    
    # Create registries.conf if it doesn't exist
    if [ ! -f /etc/containers/registries.conf ]; then
        print_status "Creating system registry configuration..."
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
    
    print_status "Registry configuration completed"
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
    
    echo
    read -p "Press Enter to continue (will edit .env after deployment)..."
fi

print_header "Port Configuration"

# Set ports based on configuration
if [ "$USE_PORT_8080" = true ]; then
    NGINX_HOST_PORT=8080
    FLASK_HOST_PORT=5000
    ACCESS_URL="http://localhost:8080"
    DIRECT_URL="http://localhost:5000"
    print_status "Using port 8080 for nginx (avoids privileged port issues)"
else
    NGINX_HOST_PORT=80
    FLASK_HOST_PORT=5000
    ACCESS_URL="http://localhost"
    DIRECT_URL="http://localhost:5000"
    print_status "Using port 80 for nginx (requires proper permissions)"
fi

print_header "Cleanup"

# Stop and remove existing containers/pods
print_status "Cleaning up existing containers..."
podman stop -a 2>/dev/null || true
podman rm -a 2>/dev/null || true
podman pod rm -a 2>/dev/null || true

# Remove orphaned containers
print_status "Cleaning up orphaned containers..."
podman pod prune -f >/dev/null 2>&1 || true

print_header "Build Application"

# Choose build method
if [ "$LIGHTWEIGHT_BUILD" = true ]; then
    DOCKERFILE="Dockerfile.dev.podman"
    IMAGE_TAG="screen-dreams:lightweight"
    print_status "Building lightweight Alpine image..."
else
    DOCKERFILE="Dockerfile.dev"
    IMAGE_TAG="screen-dreams:dev"
    print_status "Building standard Debian image..."
fi

# Build image
podman build -t $IMAGE_TAG -f $DOCKERFILE .

print_header "Container Networking"

# Create pod for networking
print_status "Creating pod for container networking..."
podman pod create --name screen-dreams-pod \
    -p $FLASK_HOST_PORT:5000 \
    -p $NGINX_HOST_PORT:80

print_header "Pull Container Images"

# Determine image names based on configuration
if [ "$USE_FULL_IMAGE_NAMES" = true ]; then
    REDIS_IMAGE="docker.io/library/redis:7-alpine"
    NGINX_IMAGE="docker.io/library/nginx:alpine"
    print_status "Using full image names..."
    
    # Pull images first
    print_status "Pulling Redis..."
    podman pull $REDIS_IMAGE
    
    print_status "Pulling nginx..."
    podman pull $NGINX_IMAGE
else
    REDIS_IMAGE="redis:7-alpine"
    NGINX_IMAGE="nginx:alpine"
    print_status "Using short image names..."
fi

print_header "Start Services"

# Start Redis container
print_status "Starting Redis container..."
podman run -d --name screen-dreams-redis-dev \
    --pod screen-dreams-pod \
    --restart unless-stopped \
    $REDIS_IMAGE

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
    -e UPLOAD_FOLDER=/app/uploads \
    -e SCREENPLAY_FOLDER=/app/screenplays \
    -v $(pwd):/app \
    -v $(pwd)/uploads:/app/uploads \
    -v $(pwd)/screenplays:/app/screenplays \
    -v $(pwd)/logs:/var/log/screen-dreams \
    $IMAGE_TAG python3 run_dev.py

# Start nginx container
print_status "Starting nginx reverse proxy..."
podman run -d --name screen-dreams-nginx-dev \
    --pod screen-dreams-pod \
    --restart unless-stopped \
    -v $(pwd)/docker/nginx/default-dev.conf:/etc/nginx/conf.d/default.conf:ro \
    -v $(pwd)/static:/var/www/static:ro \
    $NGINX_IMAGE

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
if curl -f http://localhost:$FLASK_HOST_PORT/health >/dev/null 2>&1; then
    print_status "Flask application is ready (port $FLASK_HOST_PORT)"
else
    print_warning "Flask application might still be starting..."
    print_status "Checking logs..."
    podman logs --tail=10 screen-dreams-dev
fi

# Check nginx
print_status "Checking nginx reverse proxy..."
sleep 5
if curl -f $ACCESS_URL/health >/dev/null 2>&1; then
    print_status "Nginx reverse proxy is ready (port $NGINX_HOST_PORT)"
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

# Show disk usage
print_status "Disk usage:"
df -h .

# Show image sizes
print_status "Container image sizes:"
podman images | head -5

echo
print_status "Deployment completed successfully!"
echo

print_header "Access Information"

echo "Primary Access (Recommended):"
echo "  URL: $ACCESS_URL"
echo "  Port: $NGINX_HOST_PORT"
echo
echo "Direct Access:"
echo "  URL: $DIRECT_URL"
echo "  Port: $FLASK_HOST_PORT"
echo
echo "Health Checks:"
echo "  Nginx: $ACCESS_URL/health"
echo "  Direct: $DIRECT_URL/health"

print_header "Next Steps"

echo "1. Configure AI services:"
echo "   - Edit .env file for your AI provider"
echo "   - For local AI: podman run -d --name ollama-dev --pod screen-dreams-pod ollama/ollama"
echo "   - Then: podman exec ollama-dev ollama pull llama2"
echo
echo "2. Test the application:"
echo "   - Open $ACCESS_URL in your browser"
echo "   - Create a screenplay and test AI features"
echo
echo "3. For production:"
echo "   - Change SECRET_KEY in .env"
echo "   - Set up HTTPS/SSL"
echo "   - Configure firewall rules"

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
echo "2. Verify ports: netstat -tlnp | grep -E ':($NGINX_HOST_PORT|$FLASK_HOST_PORT)'"
echo "3. Check containers: podman ps"
echo "4. Restart: podman restart [container-name]"
echo
echo "For port conflicts:"
echo "1. Stop conflicting services: sudo systemctl stop apache2 nginx"
echo "2. Or change ports with: --port-8080 option"
echo
echo "Registry issues:"
echo "1. Use: --full-image-names option"
echo "2. Or: --no-registry-config option"

echo
print_status "Thank you for deploying Screen Dreams with Podman!"
print_status "Access your application at: $ACCESS_URL"
