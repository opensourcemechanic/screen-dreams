# S3 Bucket for file storage
resource "aws_s3_bucket" "screen_dreams" {
  bucket = "${var.app_name}-${random_id.bucket_suffix.hex}"

  tags = {
    Name = var.app_name
  }
}

# S3 Bucket versioning (disabled for cost savings)
resource "aws_s3_bucket_versioning" "screen_dreams" {
  bucket = aws_s3_bucket.screen_dreams.id
  versioning_configuration {
    status = "Disabled"
  }
}

# S3 Bucket encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "screen_dreams" {
  bucket = aws_s3_bucket.screen_dreams.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# S3 Bucket public access block
resource "aws_s3_bucket_public_access_block" "screen_dreams" {
  bucket = aws_s3_bucket.screen_dreams.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# S3 Bucket lifecycle configuration
resource "aws_s3_bucket_lifecycle_configuration" "screen_dreams" {
  bucket = aws_s3_bucket.screen_dreams.id

  rule {
    id     = "delete_old_uploads"
    status = "Enabled"

    filter {
      prefix = "uploads/"
    }

    expiration {
      days = 30
    }

    noncurrent_version_expiration {
      noncurrent_days = 7
    }
  }

  rule {
    id     = "delete_old_screenplays"
    status = "Enabled"

    filter {
      prefix = "screenplays/"
    }

    expiration {
      days = 90
    }

    noncurrent_version_expiration {
      noncurrent_days = 7
    }
  }
}

# Random ID for unique bucket name
resource "random_id" "bucket_suffix" {
  byte_length = 8
}
