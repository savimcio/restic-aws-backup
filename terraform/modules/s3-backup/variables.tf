variable "bucket_name" {
  description = "Name of the S3 bucket for backups"
  type        = string
  
  validation {
    condition     = length(var.bucket_name) >= 3 && length(var.bucket_name) <= 63
    error_message = "The bucket_name must be between 3 and 63 characters."
  }
}

variable "environment" {
  description = "Environment tag (dev, staging, prod)"
  type        = string
  default     = "prod"
  
  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "The environment must be one of: dev, staging, prod."
  }
}

variable "days_until_glacier" {
  description = "Number of days before transitioning objects to Glacier storage"
  type        = number
  default     = 30
  
  validation {
    condition     = var.days_until_glacier >= 0
    error_message = "Days until Glacier transition must be a non-negative number."
  }
}

variable "enable_deep_archive" {
  description = "Whether to enable transition to Deep Archive storage"
  type        = bool
  default     = false
}

variable "days_until_deep_archive" {
  description = "Number of days before transitioning to Deep Archive storage"
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
  description = "Number of days before objects expire and are deleted"
  type        = number
  default     = 365
  
  validation {
    condition     = var.days_until_expiration >= 0
    error_message = "Days until expiration must be a non-negative number."
  }
}