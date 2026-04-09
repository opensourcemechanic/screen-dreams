# Archive application files for deployment
data "archive_file" "app_files" {
  type        = "zip"
  source_dir  = "${path.module}/.."
  output_path = "${path.module}/app-deployment.zip"
  
  excludes = [
    ".git",
    ".gitignore",
    "terraform",
    "*.pyc",
    "__pycache__",
    ".pytest_cache",
    "venv",
    ".venv",
    "env",
    ".env",
    "*.db",
    "uploads",
    "screenplays",
    "logs",
    "node_modules",
    ".vscode",
    ".idea",
    "*.log"
  ]
}

# Upload application files to S3
resource "aws_s3_object" "app_deployment" {
  bucket = aws_s3_bucket.screen_dreams.id
  key    = "deployments/app-${data.archive_file.app_files.output_md5}.zip"
  source = data.archive_file.app_files.output_path
  etag   = data.archive_file.app_files.output_md5
  
  tags = {
    Name = "${var.app_name}-app-deployment"
  }
}

# Output the S3 URL for user_data script
output "app_deployment_s3_key" {
  value = aws_s3_object.app_deployment.key
}
