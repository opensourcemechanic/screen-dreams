#!/bin/bash
# Simple Docker deployment script for Screen Dreams (WSL-compatible)

set -e

echo "=== Screen Dreams Docker Deployment (WSL Version) ==="
echo

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
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

# Simple Docker detection - just try to use it
print_status "Testing Docker availability..."
if ! docker --version >/dev/null 2>&1; then
    print_error "Docker is not available. Please ensure Docker is installed and running."
    exit 1
fi

print_status "Docker is available: $(docker --version | head -1)"

# Test Docker Compose (try both versions)
DOCKER_COMPOSE_CMD=""
if docker-compose --version >/dev/null 2>&1; then
    DOCKER_COMPOSE_CMD="docker-compose"
    print_status "Using docker-compose: $(docker-compose --version | head -1)"
elif docker compose version >/dev/null 2>&1; then
    DOCKER_COMPOSE_CMD="docker compose"
    print_status "Using docker compose plugin"
else
    print_error "Neither docker-compose nor docker compose is available."
    exit 1
fi

# Create necessary directories
print_status "Creating necessary directories..."
mkdir -p logs uploads screenplays docker/ssl

# Copy environment file if it doesn't exist
if [ ! -f .env ]; then
    print_status "Creating .env file from template..."
    cp .env.docker .env
    print_warning "Please edit .env file with your configuration before continuing."
    print_warning "Especially set your SECRET_KEY and AI provider credentials."
    read -p "Press Enter to continue after editing .env file..."
fi

# Build and start services
print_status "Building Docker images..."
$DOCKER_COMPOSE_CMD build

print_status "Starting services..."
$DOCKER_COMPOSE_CMD up -d

# Wait for services to be ready
print_status "Waiting for services to be ready..."
sleep 30

# Check service health
print_status "Checking service health..."

# Check PostgreSQL
if $DOCKER_COMPOSE_CMD exec -T postgres pg_isready -U screenwriter -d screenwriter_db > /dev/null 2>&1; then
    print_status "PostgreSQL is ready"
else
    print_warning "PostgreSQL might still be starting..."
fi

# Check Redis
if $DOCKER_COMPOSE_CMD exec -T redis redis-cli ping > /dev/null 2>&1; then
    print_status "Redis is ready"
else
    print_warning "Redis might still be starting..."
fi

# Check main application
if curl -f http://localhost:5000/health > /dev/null 2>&1; then
    print_status "Screen Dreams application is ready"
else
    print_warning "Screen Dreams application might still be starting..."
fi

# Show running services
print_status "Running services:"
$DOCKER_COMPOSE_CMD ps

# Show logs
print_status "Recent application logs:"
$DOCKER_COMPOSE_CMD logs --tail=20 screen-dreams

echo
print_status "Deployment completed!"
echo
echo "=== Access Information ==="
echo "Application: http://localhost:5000"
echo "Nginx (if enabled): http://localhost"
echo
echo "=== Useful Commands ==="
echo "View logs: $DOCKER_COMPOSE_CMD logs -f [service-name]"
echo "Stop services: $DOCKER_COMPOSE_CMD down"
echo "Restart services: $DOCKER_COMPOSE_CMD restart [service-name]"
echo "Access database: $DOCKER_COMPOSE_CMD exec postgres psql -U screenwriter -d screenwriter_db"
echo "Access Redis: $DOCKER_COMPOSE_CMD exec redis redis-cli"
echo
echo "=== AI Services ==="
echo "To start with Ollama: $DOCKER_COMPOSE_CMD --profile ai up -d"
echo "Then pull a model: $DOCKER_COMPOSE_CMD exec ollama ollama pull llama2"
echo
print_status "For production deployment, see DEPLOYMENT.md for HTTPS setup."
