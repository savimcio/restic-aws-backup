terraform {
  required_version = ">= 1.0"
  
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

locals {
  bucket_name = var.s3_bucket_name != "" ? var.s3_bucket_name : "restic-backup-${var.environment}-${random_id.suffix.hex}"
}

# Create random suffix for bucket name
resource "random_id" "suffix" {
  byte_length = 4
}

module "s3_backup" {
  source = "./modules/s3-backup"
  
  bucket_name             = local.bucket_name
  environment             = var.environment
  days_until_glacier      = var.days_until_glacier
  enable_deep_archive     = var.enable_deep_archive
  days_until_deep_archive = var.days_until_deep_archive
  enable_expiration       = var.enable_expiration
  days_until_expiration   = var.days_until_expiration
}

# Outputs for configuration
output "bucket_name" {
  value       = module.s3_backup.bucket_name
  description = "S3 bucket name for restic backups"
}

output "aws_access_key" {
  value       = module.s3_backup.aws_access_key_id
  sensitive   = true
  description = "AWS access key for restic"
}

output "aws_secret_key" {
  value       = module.s3_backup.aws_secret_access_key
  sensitive   = true
  description = "AWS secret key for restic"
}