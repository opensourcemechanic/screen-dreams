# Docker & Podman Quick Start Guide

## Quick Deployment with Nginx Port 80

Deploy Screen Dreams with nginx reverse proxy for production-ready port 80 access.

## Choose Your Container Engine

### Docker Environments
If you have Docker installed:
```bash
./deploy-docker-simple.sh
# or
./local-docker-deploy.sh
```

### Podman Environments  
If you have Podman installed (Docker alternative):
```bash
./podman-deploy.sh
```

### Not Sure Which You Have?
```bash
docker --version    # If this works, use Docker scripts
podman --version    # If this works, use Podman script
```

### Prerequisites

- Docker OR Podman installed
- Docker Compose OR Podman Compose (for Docker environments)
- Git available
- 2GB+ RAM
- 10GB+ storage

### Quick Start (5 minutes)

```bash
# 1. Clone repository
git clone https://github.com/opensourcemechanic/screen-dreams.git
cd screen-dreams

# 2. Choose your deployment method:

# For Docker environments:
chmod +x deploy-docker-simple.sh
./deploy-docker-simple.sh

# For Podman environments (recommended for local):
chmod +x podman-deploy-8080.sh
./podman-deploy-8080.sh

# 3. Access application
http://localhost:8080   # Via nginx (port 8080) - RECOMMENDED for local
http://localhost:5000   # Direct access (port 5000)
# Note: Port 8080 is default for local deployments to avoid privileged port issues
```

## Access Methods

### Primary Access (Local/Development)
- **URL**: `http://localhost:8080`
- **Port**: 8080
- **Features**: Nginx reverse proxy, avoids privileged port issues
- **Note**: Default for local Podman/Docker deployments

### Direct Access
- **URL**: `http://localhost:5000`
- **Port**: 5000
- **Features**: Direct Flask app access, debugging enabled

### Production Access (Port 80)
- **URL**: `http://localhost` (or `http://your-domain.com`)
- **Port**: 80
- **Features**: Standard HTTP access, requires sudo or systemd service
- **Note**: Use for production deployments with proper firewall setup for debugging

### Health Checks
- **Nginx**: `http://localhost:8080/health`
- **Direct**: `http://localhost:5000/health`

## Service Architecture

```
Internet (Port 80) 
    |
    v
Nginx Reverse Proxy
    |
    +-- Flask App (Port 5000)
    |
    +-- Static Files
    |
    +-- API Rate Limiting
```

## Configuration

### Environment Variables
Edit `.env` file after first deployment:

```bash
# Copy template
cp .env.docker .env

# Edit configuration
nano .env
```

**Key Settings:**
- `SECRET_KEY` - Security key (change in production)
- `AI_PROVIDER` - AI service (ollama, openai, anthropic)
- `OLLAMA_MODEL` - AI model name
- `DATABASE_URL` - Database connection

### AI Services

#### Local AI (Ollama)
```bash
# Start AI services
docker-compose -f docker-compose.dev.yml --profile ai up -d

# Pull a model
docker-compose exec ollama-dev ollama pull llama2

# Check AI status
curl http://localhost:5000/api/ai/status
```

#### Cloud AI (OpenAI/Anthropic)
```bash
# Edit .env file
AI_PROVIDER=openai
OPENAI_API_KEY=your-key-here
OPENAI_MODEL=gpt-3.5-turbo

# Restart application
docker-compose restart screen-dreams-dev
```

## Useful Commands

### Service Management
```bash
# View running services
docker-compose -f docker-compose.dev.yml ps

# View logs
docker-compose -f docker-compose.dev.yml logs -f screen-dreams-dev
docker-compose -f docker-compose.dev.yml logs -f nginx-dev

# Restart services
docker-compose -f docker-compose.dev.yml restart screen-dreams-dev
docker-compose -f docker-compose.dev.yml restart nginx-dev

# Stop all services
docker-compose -f docker-compose.dev.yml down
```

### Database Access
```bash
# Access Redis
docker-compose -f docker-compose.dev.yml exec redis-dev redis-cli

# View Redis info
docker-compose -f docker-compose.dev.yml exec redis-dev redis-cli info
```

### Development
```bash
# View application logs in real-time
docker-compose -f docker-compose.dev.yml logs -f screen-dreams-dev

# Access container shell
docker-compose -f docker-compose.dev.yml exec screen-dreams-dev bash

# Rebuild after code changes
docker-compose -f docker-compose.dev.yml build --no-cache
docker-compose -f docker-compose.dev.yml up -d
```

## Troubleshooting

### Port Conflicts
```bash
# Check what's using ports
sudo netstat -tlnp | grep :80
sudo netstat -tlnp | grep :5000

# Stop conflicting services
sudo systemctl stop nginx
sudo systemctl stop apache2
```

### Service Not Starting
```bash
# Check service status
docker-compose -f docker-compose.dev.yml ps

# View detailed logs
docker-compose -f docker-compose.dev.yml logs screen-dreams-dev

# Restart specific service
docker-compose -f docker-compose.dev.yml restart screen-dreams-dev
```

### Python Command Issues
```bash
# Check Python in container
docker-compose -f docker-compose.dev.yml exec screen-dreams-dev python3 --version

# Test Flask app manually
docker-compose -f docker-compose.dev.yml exec screen-dreams-dev python3 run_dev.py
```

### Nginx Issues
```bash
# Check nginx configuration
docker-compose -f docker-compose.dev.yml exec nginx-dev nginx -t

# View nginx logs
docker-compose -f docker-compose.dev.yml logs nginx-dev

# Restart nginx
docker-compose -f docker-compose.dev.yml restart nginx-dev
```

## Production Considerations

### Security
- Change `SECRET_KEY` in production
- Use HTTPS with SSL certificates
- Configure firewall rules
- Monitor logs regularly

### Performance
- Use PostgreSQL for production
- Configure Redis persistence
- Set up monitoring
- Plan backups

### Scaling
- Consider Kubernetes for large deployments
- Use load balancers for high availability
- Implement caching strategies
- Monitor resource usage

## Deployment Options

### Development (Current Setup)
- SQLite database
- Redis for caching
- Nginx reverse proxy
- Port 80 + 5000 access

### Production Upgrade
```bash
# Use production compose file
docker-compose -f docker-compose.yml up -d

# Features:
# - PostgreSQL database
# - SSL/HTTPS support
# - Backup services
# - Enhanced monitoring
```

## File Structure

```
screen-dreams/
|-- docker-compose.dev.yml     # Development services
|-- deploy-docker-simple.sh    # Deployment script
|-- docker/nginx/default.conf  # Nginx configuration
|-- .env.docker               # Environment template
|-- .env                      # Your configuration
|-- Dockerfile.dev            # Development image
|-- run_dev.py               # Development server
```

## Next Steps

1. **Configure AI** - Set up your preferred AI provider
2. **Customize Theme** - Modify appearance and branding
3. **Add Content** - Create your first screenplay
4. **Set up SSL** - Add HTTPS for production
5. **Configure Backup** - Set up automated backups

## Support

- **Documentation**: See `DEPLOYMENT.md` for advanced setup
- **Issues**: Report problems on GitHub
- **Community**: Join discussions for help

## Quick Verification

After deployment, verify everything works:

```bash
# Check application
curl http://localhost/health

# Check static files
curl -I http://localhost/static/css/style.css

# Check AI functionality
curl http://localhost:5000/api/ai/status

# Check nginx
curl -I http://localhost/
```

All should return HTTP 200 responses for a successful deployment!
