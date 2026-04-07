#!/bin/bash
# Kubernetes deployment script for Screen Dreams

set -e

echo "=== Screen Dreams Kubernetes Deployment ==="
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

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    print_error "kubectl is not installed. Please install kubectl first."
    exit 1
fi

# Check if cluster is accessible
if ! kubectl cluster-info &> /dev/null; then
    print_error "Cannot connect to Kubernetes cluster. Please check your kubeconfig."
    exit 1
fi

# Variables
NAMESPACE="screen-dreams"
DOCKER_IMAGE="screen-dreams:latest"
REGISTRY="" # Set your registry if needed

# Update secrets with actual values
print_status "Updating secrets..."
echo "Please update the following secrets in k8s/00-config.yaml:"
echo "- SECRET_KEY (generate a new one)"
echo "- DB_PASSWORD"
echo "- OPENAI_API_KEY (if using OpenAI)"
echo "- ANTHROPIC_API_KEY (if using Anthropic)"
echo "- IONOS_API_KEY (if using IONOS)"
echo "- SCALEWAY_API_KEY (if using Scaleway)"
echo "- Mail credentials (if using email)"
echo
read -p "Press Enter after updating secrets..."

# Build and push Docker image (if registry is set)
if [ ! -z "$REGISTRY" ]; then
    print_status "Building Docker image..."
    docker build -t $DOCKER_IMAGE .
    
    print_status "Tagging image for registry..."
    docker tag $DOCKER_IMAGE $REGISTRY/$DOCKER_IMAGE
    
    print_status "Pushing image to registry..."
    docker push $REGISTRY/$DOCKER_IMAGE
    
    # Update image in deployment files
    sed -i "s|image: screen-dreams:latest|image: $REGISTRY/$DOCKER_IMAGE|g" k8s/02-application.yaml
fi

# Apply configurations
print_status "Creating namespace and configurations..."
kubectl apply -f k8s/00-config.yaml

# Wait for configurations to be ready
print_status "Waiting for configurations to be ready..."
kubectl wait --for=condition=established --timeout=60s crd/secrets --all || true

# Deploy database services
print_status "Deploying database services..."
kubectl apply -f k8s/01-database.yaml

# Wait for database to be ready
print_status "Waiting for database to be ready..."
kubectl wait --for=condition=ready pod -l component=database -n $NAMESPACE --timeout=300s

# Deploy application
print_status "Deploying application..."
kubectl apply -f k8s/02-application.yaml

# Wait for application to be ready
print_status "Waiting for application to be ready..."
kubectl wait --for=condition=ready pod -l component=webapp -n $NAMESPACE --timeout=300s

# Deploy ingress (optional)
print_status "Deploying ingress..."
kubectl apply -f k8s/03-ingress.yaml

# Show deployment status
print_status "Deployment status:"
kubectl get all -n $NAMESPACE

# Show service URLs
print_status "Service URLs:"
kubectl get ingress -n $NAMESPACE

# Show logs
print_status "Application logs:"
kubectl logs -l component=webapp -n $NAMESPACE --tail=20

echo
print_status "Deployment completed!"
echo
echo "=== Access Information ==="
echo "To get the external IP:"
echo "kubectl get ingress -n screen-dreams"
echo
echo "To port-forward locally:"
echo "kubectl port-forward service/screen-dreams 5000:5000 -n screen-dreams"
echo
echo "=== Useful Commands ==="
echo "View pods: kubectl get pods -n $NAMESPACE"
echo "View logs: kubectl logs -f deployment/screen-dreams -n $NAMESPACE"
echo "Scale application: kubectl scale deployment screen-dreams --replicas=5 -n $NAMESPACE"
echo "Access database: kubectl exec -it deployment/postgres -n $NAMESPACE -- psql -U screenwriter -d screenwriter_db"
echo "Access Redis: kubectl exec -it deployment/redis -n $NAMESPACE -- redis-cli"
echo
echo "=== AI Services ==="
echo "To deploy with Ollama: kubectl apply -f k8s/03-ingress.yaml (includes ollama deployment)"
echo "Then pull a model: kubectl exec -it deployment/ollama -n $NAMESPACE -- ollama pull llama2"
echo
print_status "For production deployment, configure TLS certificates and monitoring."
