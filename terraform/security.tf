# Security Group for EC2 Instance
resource "aws_security_group" "screen_dreams" {
  name        = "${var.app_name}-sg"
  description = "Security group for Screen Dreams EC2 instance"
  vpc_id      = aws_vpc.screen_dreams.id

  # SSH access
  ingress {
    description = "SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_ssh_cidr]
  }

  # HTTP access
  ingress {
    description = "HTTP access"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Application port (for external access)
  ingress {
    description = "Application port"
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow external access
  }

  # Egress rules
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.app_name}-sg"
  }
}

# Security Group for RDS Database
resource "aws_security_group" "rds" {
  name        = "${var.app_name}-rds-sg"
  description = "Security group for RDS database"
  vpc_id      = aws_vpc.screen_dreams.id

  # PostgreSQL access from EC2 only
  ingress {
    description     = "PostgreSQL access from EC2"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.screen_dreams.id]
  }

  # Egress rules
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.app_name}-rds-sg"
  }
}

# IAM Role for EC2 Instance
resource "aws_iam_role" "screen_dreams" {
  name = "${var.app_name}-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name = "${var.app_name}-ec2-role"
  }
}

# IAM Policy for S3 access
resource "aws_iam_policy" "s3_access" {
  name        = "${var.app_name}-s3-policy"
  description = "S3 access policy for Screen Dreams"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.screen_dreams.arn,
          "${aws_s3_bucket.screen_dreams.arn}/*"
        ]
      }
    ]
  })
}

# IAM Policy for CloudWatch Logs
resource "aws_iam_policy" "cloudwatch_logs" {
  name        = "${var.app_name}-cloudwatch-policy"
  description = "CloudWatch Logs access policy"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:DescribeLogStreams"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

# IAM Policy for ECR access
resource "aws_iam_policy" "ecr_access" {
  name        = "${var.app_name}-ecr-policy"
  description = "ECR access policy for Screen Dreams"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:GetDownloadUrlForLayer",
          "ecr:BatchGetImage",
          "ecr:DescribeImages",
          "ecr:DescribeRepositories"
        ]
        Resource = "*"
      }
    ]
  })
}

# Attach policies to role
resource "aws_iam_role_policy_attachment" "s3_access" {
  role       = aws_iam_role.screen_dreams.name
  policy_arn = aws_iam_policy.s3_access.arn
}

resource "aws_iam_role_policy_attachment" "cloudwatch_logs" {
  role       = aws_iam_role.screen_dreams.name
  policy_arn = aws_iam_policy.cloudwatch_logs.arn
}

resource "aws_iam_role_policy_attachment" "ecr_access" {
  role       = aws_iam_role.screen_dreams.name
  policy_arn = aws_iam_policy.ecr_access.arn
}

# Instance Profile
resource "aws_iam_instance_profile" "screen_dreams" {
  name = "${var.app_name}-instance-profile"
  role = aws_iam_role.screen_dreams.name
}

# SSH Key Pair
resource "aws_key_pair" "screen_dreams" {
  key_name   = var.ssh_key_name
  public_key = var.ssh_public_key

  tags = {
    Name = var.ssh_key_name
  }
}
