# IAM resources for Restic Backup

# Create IAM user for backups
resource "aws_iam_user" "backup_user" {
  name = "backup-user-${var.environment}"
  
  tags = {
    Name        = "Restic Backup User"
    Environment = var.environment
    Purpose     = "Restic Backup Access"
    Terraform   = "true"
  }
}

resource "aws_iam_access_key" "backup_key" {
  user = aws_iam_user.backup_user.name
}

# IAM policy for S3 and Glacier operations
resource "aws_iam_policy" "backup_policy" {
  name        = "backup-policy-${var.environment}"
  description = "Policy for restic backup to S3 with Glacier transition"
  
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "BackupObjectOperations"
        Effect   = "Allow"
        Action   = [
          "s3:PutObject", 
          "s3:GetObject",
          "s3:DeleteObject",
          "s3:RestoreObject"
        ]
        Resource = "${aws_s3_bucket.backup.arn}/*"
      },
      {
        Sid      = "BackupBucketOperations"
        Effect   = "Allow"
        Action   = [
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ]
        Resource = aws_s3_bucket.backup.arn
      }
    ]
  })
}

resource "aws_iam_user_policy_attachment" "backup_attach" {
  user       = aws_iam_user.backup_user.name
  policy_arn = aws_iam_policy.backup_policy.arn
}