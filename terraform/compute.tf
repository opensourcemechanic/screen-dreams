# EC2 Instance
resource "aws_instance" "screen_dreams" {
  ami                         = "ami-0c02fb55956c7d316" # Amazon Linux 2
  instance_type               = var.instance_type
  subnet_id                   = aws_subnet.public_1.id
  vpc_security_group_ids      = [aws_security_group.screen_dreams.id]
  iam_instance_profile        = aws_iam_instance_profile.screen_dreams.name
  associate_public_ip_address = true
  key_name                    = aws_key_pair.screen_dreams.key_name

  # Wait for all dependencies to be ready
  depends_on = [null_resource.docker_build, aws_db_instance.screen_dreams, aws_s3_bucket.screen_dreams]

  # Root volume
  root_block_device {
    volume_type           = "gp2"
    volume_size           = 20
    delete_on_termination = true
    encrypted             = true
  }

  # User data script for bootstrap
  user_data = base64encode(templatefile("${path.module}/user_data.sh", {
    database_type    = var.database_type
    db_endpoint      = var.database_type == "postgres" ? aws_db_instance.screen_dreams[0].endpoint : ""
    db_port          = var.database_type == "postgres" ? tostring(aws_db_instance.screen_dreams[0].port) : "5432"
    db_name          = var.database_type == "postgres" ? aws_db_instance.screen_dreams[0].db_name : ""
    db_username      = var.database_type == "postgres" ? aws_db_instance.screen_dreams[0].username : ""
    db_password      = var.db_password
    s3_bucket        = aws_s3_bucket.screen_dreams.bucket
    sqlite_backup_bucket = var.database_type == "sqlite" ? aws_s3_bucket.sqlite_backup[0].bucket : ""
    app_deployment_s3_key = aws_s3_object.app_deployment.key
    ai_provider      = var.ai_provider
    openai_api_key   = var.openai_api_key
    anthropic_api_key = var.anthropic_api_key
    ionos_api_key    = var.ionos_api_key
    scaleway_api_key = var.scaleway_api_key
    ollama_base_url  = var.ollama_base_url
    ollama_model     = var.ollama_model
    ollama_api_key   = var.ollama_api_key
    secret_key       = var.secret_key
    region           = var.region
    app_name         = var.app_name
    aws_ecr_repository_screen_dreams = {
      registry_id = aws_ecr_repository.screen_dreams.registry_id
      repository_url = aws_ecr_repository.screen_dreams.repository_url
    }
  }))

  tags = {
    Name = var.app_name
  }
}
