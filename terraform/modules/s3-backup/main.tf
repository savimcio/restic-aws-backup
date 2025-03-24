# S3 Bucket Module for Restic Backup

resource "aws_s3_bucket" "backup" {
  bucket        = var.bucket_name
  force_destroy = true
  
  tags = {
    Name        = "Restic Backup Bucket"
    Environment = var.environment
    Purpose     = "Backup Storage"
    Terraform   = "true"
  }
}

# Enable versioning for backups
resource "aws_s3_bucket_versioning" "backup" {
  bucket = aws_s3_bucket.backup.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Enable bucket encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "backup" {
  bucket = aws_s3_bucket.backup.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Restrict public access
resource "aws_s3_bucket_public_access_block" "backup" {
  bucket                  = aws_s3_bucket.backup.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Configure lifecycle policies for Glacier transition
resource "aws_s3_bucket_lifecycle_configuration" "backup" {
  bucket = aws_s3_bucket.backup.id

  rule {
    id     = "glacier-transition"
    status = "Enabled"

    filter {
      prefix = ""
    }

    # Move to Glacier after specified days
    transition {
      days          = var.days_until_glacier
      storage_class = "GLACIER"
    }

    # Move to Deep Archive after specified days if enabled
    dynamic "transition" {
      for_each = var.enable_deep_archive ? [1] : []
      content {
        days          = var.days_until_deep_archive
        storage_class = "DEEP_ARCHIVE"
      }
    }

    # Optional expiration
    dynamic "expiration" {
      for_each = var.enable_expiration ? [1] : []
      content {
        days = var.days_until_expiration
      }
    }
  }
}