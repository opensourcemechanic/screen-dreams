# S3 Bucket for SQLite database backup (only for SQLite)
resource "aws_s3_bucket" "sqlite_backup" {
  count  = var.database_type == "sqlite" ? 1 : 0
  bucket = "${var.app_name}-sqlite-backup-${random_string.bucket_suffix.result}"
  
  tags = {
    Name = "${var.app_name}-sqlite-backup"
  }
}

# S3 Bucket versioning for SQLite backups
resource "aws_s3_bucket_versioning" "sqlite_backup" {
  count  = var.database_type == "sqlite" ? 1 : 0
  bucket = aws_s3_bucket.sqlite_backup[0].id
  versioning_configuration {
    status = "Enabled"
  }
}

# IAM policy for SQLite backup access (only for SQLite)
resource "aws_iam_policy" "sqlite_backup" {
  count       = var.database_type == "sqlite" ? 1 : 0
  name        = "${var.app_name}-sqlite-backup-policy"
  description = "S3 access for SQLite database backups"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:ListBucket"
        ]
        Resource = [
          aws_s3_bucket.sqlite_backup[0].arn,
          "${aws_s3_bucket.sqlite_backup[0].arn}/*"
        ]
      }
    ]
  })
}

# Attach SQLite backup policy to EC2 role (only for SQLite)
resource "aws_iam_role_policy_attachment" "sqlite_backup" {
  count       = var.database_type == "sqlite" ? 1 : 0
  role       = aws_iam_role.screen_dreams.name
  policy_arn = aws_iam_policy.sqlite_backup[0].arn
}
