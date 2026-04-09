# PowerShell script to deploy Screen Dreams to ECR and EC2
param(
    [Parameter(Mandatory=$true)]
    [string]$EC2_IP
)

$ECR_REGISTRY = "314272288726.dkr.ecr.us-east-1.amazonaws.com"
$APP_NAME = "screen-dreams"

Write-Host "Deploying Screen Dreams to EC2: $EC2_IP" -ForegroundColor Green

Write-Host "Step 1: Uploading files to EC2..." -ForegroundColor Yellow
# Upload all necessary files
scp -r app/ static/ templates/ run.py requirements.txt Dockerfile gunicorn.conf.py ec2-user@$EC2_IP`:/opt/screen-dreams/

Write-Host "Step 2: Building Docker image on EC2..." -ForegroundColor Yellow
ssh ec2-user@$EC2_IP "cd /opt/screen-dreams && docker build -t $ECR_REGISTRY/$APP_NAME`:latest ."

Write-Host "Step 3: Pushing to ECR..." -ForegroundColor Yellow
ssh ec2-user@$EC2_IP "docker push $ECR_REGISTRY/$APP_NAME`:latest"

Write-Host "Step 4: Restarting services..." -ForegroundColor Yellow
ssh ec2-user@$EC2_IP "docker-compose down && docker-compose up -d"

Write-Host "Step 5: Checking deployment..." -ForegroundColor Yellow
ssh ec2-user@$EC2_IP "docker-compose logs screen-dreams | tail -10"

Write-Host "Deployment complete! Test your app at: http://$EC2_IP" -ForegroundColor Green
Write-Host "Check health: curl http://$EC2_IP/health" -ForegroundColor Green
