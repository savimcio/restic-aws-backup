output "bucket_name" {
  description = "Name of the created S3 bucket for restic backups"
  value       = aws_s3_bucket.backup.id
}

output "bucket_arn" {
  description = "ARN of the created S3 bucket"
  value       = aws_s3_bucket.backup.arn
}

output "aws_access_key_id" {
  description = "AWS access key for restic"
  value       = aws_iam_access_key.backup_key.id
  sensitive   = true
}

output "aws_secret_access_key" {
  description = "AWS secret key for restic"
  value       = aws_iam_access_key.backup_key.secret
  sensitive   = true
}

output "backup_user_name" {
  description = "Name of the IAM user created for backups"
  value       = aws_iam_user.backup_user.name
}