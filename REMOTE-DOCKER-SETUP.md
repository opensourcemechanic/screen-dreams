# Remote Docker Setup Guide

## Fix Docker Installation and Permissions

### Step 1: Install Docker (if not installed)

```bash
# For Ubuntu/Debian:
sudo apt update
sudo apt install -y docker.io docker-compose

# For CentOS/RHEL:
sudo yum install -y docker docker-compose

# For Amazon Linux 2:
sudo yum install -y docker
sudo systemctl start docker
sudo systemctl enable docker
```

### Step 2: Add Docker Group and User

```bash
# Create docker group if it doesn't exist
sudo groupadd docker

# Add your user to docker group
sudo usermod -aG docker $USER

# Activate the group changes (no logout needed)
newgrp docker
```

### Step 3: Verify Docker Installation

```bash
# Check if Docker is running
sudo systemctl status docker

# Start Docker if not running
sudo systemctl start docker
sudo systemctl enable docker

# Test Docker without sudo
docker --version
docker ps
```

### Step 4: Deploy Screen Dreams

```bash
# Navigate to your project directory
cd /path/to/screen-dreams

# Set up environment file
cp .env.docker .env
nano .env  # Edit with your values

# Run deployment
./local-docker-deploy.sh
```

## Alternative: Use sudo for Docker Commands

If group permissions don't work, modify the deployment script to use sudo:

```bash
# Edit local-docker-deploy.sh
# Add sudo to Docker commands:
sudo docker-compose -f docker-compose.dev.yml up -d
sudo docker ps
```

## Troubleshooting

### Docker Service Issues
```bash
# Check Docker daemon
sudo systemctl status docker

# Restart Docker
sudo systemctl restart docker

# Check Docker logs
sudo journalctl -u docker
```

### Permission Issues
```bash
# Check current groups
groups

# Verify docker group exists
getent group docker

# Add user again if needed
sudo usermod -aG docker $USER
newgrp docker
```

### Docker Socket Permissions
```bash
# Check socket permissions
ls -la /var/run/docker.sock

# Fix socket permissions (temporary)
sudo chmod 666 /var/run/docker.sock
```

## Complete Setup Commands

Copy and paste this sequence:

```bash
# 1. Install Docker
sudo apt update && sudo apt install -y docker.io docker-compose

# 2. Start and enable Docker
sudo systemctl start docker
sudo systemctl enable docker

# 3. Add user to docker group
sudo groupadd docker 2>/dev/null || true
sudo usermod -aG docker $USER
newgrp docker

# 4. Verify installation
docker --version
docker ps

# 5. Deploy Screen Dreams
cd /path/to/screen-dreams
cp .env.docker .env
nano .env
./local-docker-deploy.sh
```

## If All Else Fails: Use Docker Compose Directly

```bash
# Install Docker Compose standalone
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Then run deployment
docker-compose -f docker-compose.dev.yml up -d
```
