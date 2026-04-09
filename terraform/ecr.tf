# ECR Repository for Docker Image
resource "aws_ecr_repository" "screen_dreams" {
  name                 = "${var.app_name}"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "${var.app_name}-ecr"
  }
}

# ECR Lifecycle Policy
resource "aws_ecr_lifecycle_policy" "screen_dreams" {
  repository = aws_ecr_repository.screen_dreams.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last 10 images"
        selection = {
          tagStatus     = "tagged"
          tagPrefixList = ["v"]
          countType     = "imageCountMoreThan"
          countNumber  = 10
        }
        action = {
          type = "expire"
        }
      },
      {
        rulePriority = 2
        description  = "Delete untagged images older than 1 day"
        selection = {
          tagStatus   = "untagged"
          countType   = "sinceImagePushed"
          countUnit   = "days"
          countNumber = 1
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}

# Local file exec to build and push Docker image
resource "null_resource" "docker_build" {
  depends_on = [aws_ecr_repository.screen_dreams]

  provisioner "local-exec" {
    command = <<-EOT
      aws ecr get-login-password --region ${var.region} | docker login --username AWS --password-stdin ${aws_ecr_repository.screen_dreams.registry_id}.dkr.ecr.${var.region}.amazonaws.com
      
      cd .. && docker build -t ${aws_ecr_repository.screen_dreams.repository_url}:latest .
      
      docker push ${aws_ecr_repository.screen_dreams.repository_url}:latest
    EOT
  }

  triggers = {
    # Rebuild when Dockerfile changes
    dockerfile_content = filesha256("${path.module}/../Dockerfile")
    # Rebuild when app code changes
    app_content_hash  = sha256(join("", [for f in fileset("${path.module}/../app", "**") : filesha256("${path.module}/../app/${f}")]))
  }
}
