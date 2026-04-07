#!/bin/bash
# Docker deployment script for Screen Dreams

set -e

echo "=== Screen Dreams Docker Deployment ==="
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

# Check if Docker is installed
if ! which docker &> /dev/null; then
    print_error "Docker is not installed. Please install Docker first."
    exit 1
fi

# Check if Docker is running
if ! docker info &> /dev/null; then
    print_error "Docker is not running. Please start Docker daemon."
    exit 1
fi

# Check if Docker Compose is installed
if ! which docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    print_error "Docker Compose is not installed. Please install Docker Compose first."
    exit 1
fi

# Determine Docker Compose command
if which docker-compose &> /dev/null; then
    DOCKER_COMPOSE_CMD="docker-compose"
else
    DOCKER_COMPOSE_CMD="docker compose"
fi

print_status "Using Docker Compose command: $DOCKER_COMPOSE_CMD"

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
    print_error "PostgreSQL is not ready"
fi

# Check Redis
if $DOCKER_COMPOSE_CMD exec -T redis redis-cli ping > /dev/null 2>&1; then
    print_status "Redis is ready"
else
    print_error "Redis is not ready"
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
$DOCKER_COMPOSE_CMD logs --tail=50 screen-dreams

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
