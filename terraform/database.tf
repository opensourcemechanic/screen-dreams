# RDS Subnet Group (only for PostgreSQL)
resource "aws_db_subnet_group" "screen_dreams" {
  count      = var.database_type == "postgres" ? 1 : 0
  name       = "${var.app_name}-subnet-group"
  subnet_ids = [aws_subnet.private_1.id, aws_subnet.private_2.id]

  tags = {
    Name = "${var.app_name}-subnet-group"
  }
}

# RDS Database Instance (only for PostgreSQL)
resource "aws_db_instance" "screen_dreams" {
  count      = var.database_type == "postgres" ? 1 : 0
  identifier = var.app_name

  engine         = "postgres"
# engine_version = "14.9"  # Let AWS choose default version
  instance_class = var.db_instance_class

  allocated_storage     = 20
  max_allocated_storage = 30
  storage_type          = "gp2"
  storage_encrypted     = true

  db_name  = var.db_name
  username = var.db_username
  password = var.db_password

  port = 5432

  vpc_security_group_ids = [aws_security_group.rds.id]
  db_subnet_group_name   = aws_db_subnet_group.screen_dreams[0].name

  # Backup configuration (Free Tier compliant)
  backup_retention_period = 0  # Free Tier requires 0 days
  backup_window          = "03:00-04:00"
  maintenance_window     = "sun:04:00-sun:05:00"

  # Monitoring (basic, free tier)
  monitoring_interval = 0
  performance_insights_enabled = false

  # Deletion protection
  deletion_protection = false
  skip_final_snapshot = true

  # Tags
  tags = {
    Name = var.app_name
  }
}
