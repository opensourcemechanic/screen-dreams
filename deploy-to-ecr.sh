#!/bin/bash

# Script to deploy Screen Dreams to ECR and EC2
# Run this from your local machine after setting EC2_IP

set -e

EC2_IP=${1:-"YOUR_EC2_IP"}
ECR_REGISTRY="314272288726.dkr.ecr.us-east-1.amazonaws.com"
APP_NAME="screen-dreams"

echo "Deploying Screen Dreams to EC2: $EC2_IP"

# Check if EC2_IP is set
if [ "$EC2_IP" = "YOUR_EC2_IP" ]; then
    echo "Please set EC2_IP: ./deploy-to-ecr.sh YOUR_EC2_IP"
    exit 1
fi

echo "Step 1: Uploading files to EC2..."
# Upload all necessary files
scp -r app/ static/ templates/ run.py requirements.txt Dockerfile gunicorn.conf.py ec2-user@$EC2_IP:/opt/screen-dreams/

echo "Step 2: Building Docker image on EC2..."
ssh ec2-user@$EC2_IP "cd /opt/screen-dreams && docker build -t $ECR_REGISTRY/$APP_NAME:latest ."

echo "Step 3: Pushing to ECR..."
ssh ec2-user@$EC2_IP "docker push $ECR_REGISTRY/$APP_NAME:latest"

echo "Step 4: Restarting services..."
ssh ec2-user@$EC2_IP "docker-compose down && docker-compose up -d"

echo "Step 5: Checking deployment..."
ssh ec2-user@$EC2_IP "docker-compose logs screen-dreams | tail -10"

echo "Deployment complete! Test your app at: http://$EC2_IP"
echo "Check health: curl http://$EC2_IP/health"
