#!/bin/bash
# Local Docker Quick Deployment Script
# Optimized for any local VM or server with existing Docker

set -e

echo "=== Screen Dreams Local Docker Deployment ==="
echo "This script deploys Screen Dreams with nginx port 80 access"
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

# Check if running as root (not recommended)
if [ "$EUID" -eq 0 ]; then
    print_warning "Running as root is not recommended. Consider using a regular user with Docker access."
    read -p "Continue anyway? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

print_header "System Check"

# Check Docker
print_status "Checking Docker installation..."
if ! command -v docker >/dev/null 2>&1; then
    print_error "Docker is not installed. Please install Docker first."
    echo "Visit: https://docs.docker.com/get-docker/"
    exit 1
fi

print_status "Docker found: $(docker --version | head -1)"

# Check Docker Compose
print_status "Checking Docker Compose..."
DOCKER_COMPOSE_CMD=""
if docker-compose --version >/dev/null 2>&1; then
    DOCKER_COMPOSE_CMD="docker-compose"
    print_status "Using docker-compose: $(docker-compose --version | head -1)"
elif docker compose version >/dev/null 2>&1; then
    DOCKER_COMPOSE_CMD="docker compose"
    print_status "Using docker compose plugin"
else
    print_error "Docker Compose is not installed."
    echo "Install Docker Compose: https://docs.docker.com/compose/install/"
    exit 1
fi

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

print_header "Deployment"

# Stop existing services
print_status "Stopping any existing services..."
$DOCKER_COMPOSE_CMD -f docker-compose.dev.yml down 2>/dev/null || true

# Remove orphaned containers
print_status "Cleaning up orphaned containers..."
docker container prune -f >/dev/null 2>&1 || true

# Build and start services
print_status "Building Docker images..."
$DOCKER_COMPOSE_CMD -f docker-compose.dev.yml build

print_status "Starting services..."
$DOCKER_COMPOSE_CMD -f docker-compose.dev.yml up -d

print_header "Service Health Check"

# Wait for services to start
print_status "Waiting for services to initialize..."
sleep 20

# Check Redis
print_status "Checking Redis..."
if $DOCKER_COMPOSE_CMD -f docker-compose.dev.yml exec -T redis-dev redis-cli ping >/dev/null 2>&1; then
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
    $DOCKER_COMPOSE_CMD -f docker-compose.dev.yml logs --tail=10 screen-dreams-dev
fi

# Check nginx
print_status "Checking nginx reverse proxy..."
sleep 5
if curl -f http://localhost/health >/dev/null 2>&1; then
    print_status "Nginx reverse proxy is ready (port 80)"
else
    print_warning "Nginx might still be starting..."
    print_status "Checking nginx logs..."
    $DOCKER_COMPOSE_CMD -f docker-compose.dev.yml logs --tail=10 nginx-dev
fi

print_header "Deployment Summary"

# Show running services
print_status "Running services:"
$DOCKER_COMPOSE_CMD -f docker-compose.dev.yml ps

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
echo "   - For local AI: docker-compose -f docker-compose.dev.yml --profile ai up -d"
echo "   - Then: docker-compose exec ollama-dev ollama pull llama2"
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

print_header "Useful Commands"

echo "View logs:"
echo "  $DOCKER_COMPOSE_CMD -f docker-compose.dev.yml logs -f screen-dreams-dev"
echo "  $DOCKER_COMPOSE_CMD -f docker-compose.dev.yml logs -f nginx-dev"
echo
echo "Restart services:"
echo "  $DOCKER_COMPOSE_CMD -f docker-compose.dev.yml restart screen-dreams-dev"
echo "  $DOCKER_COMPOSE_CMD -f docker-compose.dev.yml restart nginx-dev"
echo
echo "Stop all services:"
echo "  $DOCKER_COMPOSE_CMD -f docker-compose.dev.yml down"
echo
echo "Access Redis:"
echo "  $DOCKER_COMPOSE_CMD -f docker-compose.dev.yml exec redis-dev redis-cli"

print_header "Troubleshooting"

echo "If services don't start:"
echo "1. Check logs: $DOCKER_COMPOSE_CMD -f docker-compose.dev.yml logs"
echo "2. Verify ports: sudo netstat -tlnp | grep -E ':(80|5000)'"
echo "3. Check Docker: docker ps"
echo "4. Restart: $DOCKER_COMPOSE_CMD -f docker-compose.dev.yml restart"
echo
echo "For port conflicts:"
echo "1. Stop conflicting services: sudo systemctl stop apache2 nginx"
echo "2. Or change ports in docker-compose.dev.yml"

echo
print_status "Thank you for deploying Screen Dreams locally!"
print_status "For more help, see DOCKER-QUICK-START.md"
