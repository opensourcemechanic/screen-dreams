# Docker & Kubernetes Deployment Guide

## Table of Contents
1. [Docker Deployment](#docker-deployment)
2. [Kubernetes Deployment](#kubernetes-deployment)
3. [Environment Configuration](#environment-configuration)
4. [AI Provider Setup](#ai-provider-setup)
5. [Monitoring & Scaling](#monitoring--scaling)
6. [Troubleshooting](#troubleshooting)

---

## Docker Deployment

### Quick Start
```bash
# Clone and setup
git clone https://github.com/opensourcemechanic/screen-dreams.git
cd screen-dreams

# Deploy with Docker
./deploy-docker.sh
```

### Manual Docker Deployment

#### 1. Environment Setup
```bash
# Copy environment template
cp .env.docker .env

# Edit with your configuration
nano .env
```

#### 2. Build and Run
```bash
# Build the image
docker build -t screen-dreams .

# Run with Docker Compose
docker-compose up -d

# Or with AI services
docker-compose --profile ai up -d
```

#### 3. Service Management
```bash
# View running services
docker-compose ps

# View logs
docker-compose logs -f screen-dreams

# Stop services
docker-compose down

# Restart specific service
docker-compose restart screen-dreams
```

### Docker Services

| Service | Port | Description |
|---------|------|-------------|
| screen-dreams | 5000 | Main Flask application |
| postgres | 5432 | PostgreSQL database |
| redis | 6379 | Redis cache and rate limiting |
| ollama | 11434 | Local AI service (optional) |
| nginx | 80/443 | Reverse proxy (optional) |

### Production Docker Setup

#### 1. HTTPS with Nginx
```bash
# Generate SSL certificates
./setup-ssl.sh screendreams.com

# Start with HTTPS
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up -d
```

#### 2. Environment Variables
```bash
# Production .env example
FLASK_ENV=production
FLASK_DEBUG=False
SECRET_KEY=your-256-character-secret-key
DATABASE_URL=postgresql://screenwriter:password@postgres:5432/screenwriter_db
AI_PROVIDER=ollama
OLLAMA_BASE_URL=http://ollama:11434
```

---

## Kubernetes Deployment

### Quick Start
```bash
# Clone and setup
git clone https://github.com/opensourcemechanic/screen-dreams.git
cd screen-dreams

# Deploy to Kubernetes
./deploy-k8s.sh
```

### Manual Kubernetes Deployment

#### 1. Update Secrets
Edit `k8s/00-config.yaml` and update the secret values:
```yaml
data:
  SECRET_KEY: <base64-encoded-secret>
  DB_PASSWORD: <base64-encoded-password>
  OPENAI_API_KEY: <base64-encoded-api-key>
  # ... other secrets
```

#### 2. Deploy Components
```bash
# Deploy configuration and secrets
kubectl apply -f k8s/00-config.yaml

# Deploy database services
kubectl apply -f k8s/01-database.yaml

# Deploy application
kubectl apply -f k8s/02-application.yaml

# Deploy ingress and AI services
kubectl apply -f k8s/03-ingress.yaml
```

#### 3. Verify Deployment
```bash
# Check pod status
kubectl get pods -n screen-dreams

# Check services
kubectl get services -n screen-dreams

# Check ingress
kubectl get ingress -n screen-dreams

# View application logs
kubectl logs -f deployment/screen-dreams -n screen-dreams
```

### Kubernetes Components

| Component | Replicas | Resources | Description |
|-----------|----------|-----------|-------------|
| screen-dreams | 3-10 | 512Mi-1Gi CPU | Main Flask application |
| postgres | 1 | 256Mi-512Mi CPU | PostgreSQL database |
| redis | 1 | 128Mi-256Mi CPU | Redis cache |
| ollama | 1 | 2Gi-4Gi CPU | Local AI service |

### Production Kubernetes Setup

#### 1. Auto-scaling
```yaml
# Horizontal Pod Autoscaler
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: screen-dreams-hpa
spec:
  minReplicas: 3
  maxReplicas: 10
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
```

#### 2. Resource Limits
```yaml
# Production resource requests/limits
resources:
  requests:
    memory: "512Mi"
    cpu: "500m"
  limits:
    memory: "1Gi"
    cpu: "1000m"
```

#### 3. Health Checks
```yaml
# Liveness and readiness probes
livenessProbe:
  httpGet:
    path: /health
    port: 5000
  initialDelaySeconds: 30
  periodSeconds: 10
readinessProbe:
  httpGet:
    path: /health
    port: 5000
  initialDelaySeconds: 5
  periodSeconds: 5
```

---

## Environment Configuration

### Required Variables
```bash
# Application
SECRET_KEY=your-256-character-secret-key
FLASK_ENV=production
FLASK_DEBUG=False

# Database
DATABASE_URL=postgresql://user:pass@host:5432/dbname

# AI Provider (choose one)
AI_PROVIDER=ollama|openai|anthropic|ionos|scaleway

# Security
SESSION_COOKIE_SECURE=True
SESSION_COOKIE_HTTPONLY=True
```

### Optional Variables
```bash
# Email
MAIL_SERVER=smtp.gmail.com
MAIL_PORT=587
MAIL_USE_TLS=True
MAIL_USERNAME=your-email@gmail.com
MAIL_PASSWORD=your-app-password

# Rate Limiting
RATELIMIT_STORAGE_URL=redis://redis:6379/0

# File Uploads
MAX_CONTENT_LENGTH=104857600  # 100MB
UPLOAD_FOLDER=/app/uploads
```

---

## AI Provider Setup

### Ollama (Local AI)
```bash
# Environment
AI_PROVIDER=ollama
OLLAMA_BASE_URL=http://ollama:11434
OLLAMA_MODEL=llama2

# Pull models
docker-compose exec ollama ollama pull llama2
docker-compose exec ollama ollama pull mistral
```

### OpenAI
```bash
# Environment
AI_PROVIDER=openai
OPENAI_API_KEY=your-openai-api-key
OPENAI_MODEL=gpt-3.5-turbo
```

### Anthropic Claude
```bash
# Environment
AI_PROVIDER=anthropic
ANTHROPIC_API_KEY=your-anthropic-api-key
ANTHROPIC_MODEL=claude-3-sonnet-20240229
```

### IONOS AI (European)
```bash
# Environment
AI_PROVIDER=ionos
IONOS_API_KEY=your-ionos-api-key
IONOS_MODEL=llama-3.3-70b
```

### Scaleway AI (European)
```bash
# Environment
AI_PROVIDER=scaleway
SCALEWAY_API_KEY=your-scaleway-api-key
SCALEWAY_MODEL=llama-3.3-70b
```

---

## Monitoring & Scaling

### Docker Monitoring
```bash
# Resource usage
docker stats

# Container logs
docker logs -f screen-dreams-app

# Health checks
curl http://localhost:5000/health
```

### Kubernetes Monitoring
```bash
# Resource usage
kubectl top pods -n screen-dreams

# Events
kubectl get events -n screen-dreams --sort-by=.metadata.creationTimestamp

# Describe pod
kubectl describe pod <pod-name> -n screen-dreams
```

### Scaling Strategies

#### Docker Scaling
```bash
# Scale with Docker Compose
docker-compose up -d --scale screen-dreams=3

# Or use Docker Swarm
docker swarm init
docker stack deploy -c docker-compose.yml screen-dreams
```

#### Kubernetes Scaling
```bash
# Manual scaling
kubectl scale deployment screen-dreams --replicas=5 -n screen-dreams

# Auto-scaling (configured in HPA)
kubectl get hpa -n screen-dreams
```

---

## Troubleshooting

### Common Issues

#### 1. Database Connection Failed
```bash
# Docker
docker-compose logs postgres

# Kubernetes
kubectl logs deployment/postgres -n screen-dreams

# Check connection string
echo $DATABASE_URL
```

#### 2. AI Service Not Responding
```bash
# Check Ollama
curl http://localhost:11434/api/tags

# Check configuration
docker-compose exec screen-dreams env | grep AI_
```

#### 3. High Memory Usage
```bash
# Docker
docker stats --no-stream

# Kubernetes
kubectl top pods -n screen-dreams

# Reduce replicas
kubectl scale deployment screen-dreams --replicas=2 -n screen-dreams
```

#### 4. SSL Certificate Issues
```bash
# Check certificates
openssl x509 -in /path/to/cert.pem -text -noout

# Renew certificates
certbot renew
```

### Health Checks
```bash
# Application health
curl http://localhost:5000/health

# Database health
docker-compose exec postgres pg_isready

# Redis health
docker-compose exec redis redis-cli ping
```

### Log Analysis
```bash
# Docker logs
docker-compose logs --tail=100 screen-dreams

# Kubernetes logs
kubectl logs -l component=webapp -n screen-dreams --tail=100

# Error logs only
docker-compose logs screen-dreams | grep ERROR
```

---

## Security Considerations

### Docker Security
```bash
# Use non-root user
USER screenwriter

# Read-only filesystem
--read-only

# Resource limits
--memory=1g --cpus=1.0
```

### Kubernetes Security
```yaml
# Security context
securityContext:
  runAsNonRoot: true
  runAsUser: 1000
  fsGroup: 1000
  readOnlyRootFilesystem: true
```

### Network Security
```bash
# Network policies
kubectl apply -f k8s/network-policy.yaml

# Service mesh (optional)
istioctl install
```

---

## Performance Optimization

### Database Optimization
```sql
-- PostgreSQL performance settings
ALTER SYSTEM SET shared_buffers = '128MB';
ALTER SYSTEM SET effective_cache_size = '512MB';
ALTER SYSTEM SET maintenance_work_mem = '32MB';
```

### Redis Optimization
```bash
# Redis configuration
maxmemory 256mb
maxmemory-policy allkeys-lru
save 900 1
```

### Application Caching
```python
# Flask caching
from flask_caching import Cache
cache = Cache(config={'CACHE_TYPE': 'redis'})

@cache.memoize(timeout=300)
def expensive_function():
    # Cache expensive operations
    pass
```

---

## Backup & Recovery

### Docker Backup
```bash
# Database backup
docker-compose exec postgres pg_dump -U screenwriter screenwriter_db > backup.sql

# Volume backup
docker run --rm -v screen-dreams_postgres_data:/data -v $(pwd):/backup alpine tar czf /backup/postgres-backup.tar.gz -C /data .
```

### Kubernetes Backup
```bash
# Database backup
kubectl exec deployment/postgres -n screen-dreams -- pg_dump -U screenwriter screenwriter_db > backup.sql

# Persistent volume backup
kubectl get pvc -n screen-dreams
```

### Recovery
```bash
# Restore database
docker-compose exec -T postgres psql -U screenwriter -d screenwriter_db < backup.sql

# Kubernetes restore
kubectl exec -i deployment/postgres -n screen-dreams -- psql -U screenwriter -d screenwriter_db < backup.sql
```

---

## Next Steps

1. **Production Setup**: Configure HTTPS, monitoring, and backups
2. **CI/CD Pipeline**: Set up automated testing and deployment
3. **Monitoring**: Implement Prometheus/Grafana for observability
4. **Security**: Add network policies and security scanning
5. **Scaling**: Configure auto-scaling based on traffic patterns

For more detailed information, see the individual configuration files and the main README.md.
