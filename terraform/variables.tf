variable "aws_region" {
  description = "AWS region where resources will be created"
  type        = string
  default     = "us-east-1"
  
  validation {
    condition     = contains([
      "us-east-1", "us-east-2", "us-west-1", "us-west-2", 
      "eu-west-1", "eu-west-2", "eu-west-3", "eu-central-1", 
      "ap-northeast-1", "ap-northeast-2", "ap-southeast-1", "ap-southeast-2",
      "ca-central-1", "sa-east-1"
    ], var.aws_region)
    error_message = "Please provide a valid AWS region."
  }
}

variable "s3_bucket_name" {
  description = "S3 bucket name for storing restic backups (leave empty for auto-generated name)"
  type        = string
  default     = ""
  
  validation {
    condition     = var.s3_bucket_name == "" || (length(var.s3_bucket_name) >= 3 && length(var.s3_bucket_name) <= 63)
    error_message = "The s3_bucket_name must be empty or between 3 and 63 characters."
  }
}

variable "environment" {
  description = "Environment (dev, staging, prod)"
  type        = string
  default     = "prod"
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "The environment must be one of: dev, staging, prod."
  }
}

variable "days_until_glacier" {
  description = "Number of days before transitioning objects to Glacier storage class"
  type        = number
  default     = 30
  
  validation {
    condition     = var.days_until_glacier >= 0
    error_message = "Days until Glacier transition must be a non-negative number."
  }
}

variable "enable_deep_archive" {
  description = "Whether to enable transition to Deep Archive storage class"
  type        = bool
  default     = false
}

variable "days_until_deep_archive" {
  description = "Number of days before transitioning objects to Deep Archive storage class"
  type        = number
  default     = 90
  
  validation {
    condition     = var.days_until_deep_archive >= 0
    error_message = "Days until Deep Archive transition must be a non-negative number."
  }
}

variable "enable_expiration" {
  description = "Whether to enable object expiration"
  type        = bool
  default     = false
}

variable "days_until_expiration" {
  description = "Number of days before objects expire and are deleted (if enabled)"
  type        = number
  default     = 365
  
  validation {
    condition     = var.days_until_expiration >= 0
    error_message = "Days until expiration must be a non-negative number."
  }
}