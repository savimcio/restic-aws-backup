# Restic AWS Backup

A simple backup solution for Linux/Unix systems using [Restic](https://restic.net/) and AWS S3/Glacier. This project provides an easy way to configure and automate encrypted backups with cost-optimized storage through lifecycle policies.

## Quick Start

```sh
# Download the script
curl -s https://raw.githubusercontent.com/savimcio/restic-aws-backup/main/restic-aws.sh -o restic-aws.sh
chmod +x restic-aws.sh

# Install, configure, and run your first backup
sudo ./restic-aws.sh install
sudo ./restic-aws.sh configure
sudo ./restic-aws.sh backup
```

That's it! Your system is now configured for daily backups.

## Table of Contents

- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
- [Configuration](#configuration)
- [Usage](#usage)
- [AWS Infrastructure Setup](#aws-infrastructure-setup)
- [Retention Policy](#retention-policy)
- [Security](#security)
- [Advanced Configuration](#advanced-configuration)
- [Troubleshooting](#troubleshooting)
- [Uninstallation](#uninstallation)
- [Project Structure](#project-structure)
- [Testing](#testing)
- [Terraform Infrastructure](#terraform-infrastructure)
- [License](#license)

## Features

- **Simple Installation**: Single script handles everything
- **Encrypted Backups**: End-to-end encryption for your data
- **AWS S3 Integration**: Reliable cloud storage
- **Glacier Support**: Cost-effective long-term storage
- **Automated Scheduling**: Set-and-forget daily backups
- **Retention Policies**: Automatically manages backup lifecycle
- **Deduplication**: Only stores unique data to save space
- **Multiple Systems**: Back up multiple machines to one bucket

## Requirements

- Linux/Unix system with sudo access
- AWS account with access credentials
- Internet connection
- 10MB disk space (plus space for backups)

## Installation

### Method 1: Direct Installation (Recommended)

```sh
# Download and make executable
curl -s https://raw.githubusercontent.com/savimcio/restic-aws-backup/main/restic-aws.sh -o restic-aws.sh
chmod +x restic-aws.sh

# Install (requires sudo)
sudo ./restic-aws.sh install
```

The install process:
1. Installs restic on your system
2. Creates configuration directories
3. Sets up systemd service for scheduled backups
4. Generates a secure password for your backups

### Method 2: Manual Clone

```sh
# Clone the repository
git clone https://github.com/savimcio/restic-aws-backup.git
cd restic-aws-backup

# Install
sudo ./restic-aws.sh install
```

## Configuration

After installation, configure your AWS settings:

```sh
sudo ./restic-aws.sh configure
```

You'll be prompted for:
- AWS Access Key ID
- AWS Secret Access Key
- S3 Bucket Name
- AWS Region
- Directories to back up (comma-separated, optional)
- Retention policy settings (optional)

All settings are stored in a single configuration file:
```
/etc/restic-aws-backup/restic-aws.conf
```

Example configuration:
```sh
# AWS S3 Configuration
AWS_ACCESS_KEY_ID=AKIAXXXXXXXXXXXXXXXX
AWS_SECRET_ACCESS_KEY=XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX
BUCKET_NAME=my-backup-bucket
AWS_REGION=us-east-1

# Backup Paths (comma-separated)
BACKUP_PATHS="/home,/etc,/var/www"

# Exclude Patterns (comma-separated)
EXCLUDE_PATTERNS=".cache/,/tmp/,/proc/,/sys/,/dev/,/run/,/var/run/,/var/cache/,*.log"

# Retention Policy
KEEP_DAILY=7
KEEP_WEEKLY=4
KEEP_MONTHLY=3

# Encryption Password
BACKUP_PASSWORD=your-secure-password-here
```

## Usage

### Common Commands

```sh
# Run backup manually
sudo ./restic-aws.sh backup
# Or use the symlink created during installation
sudo restic-aws backup

# List all backups
sudo restic-aws snapshots

# Restore latest backup to a folder
sudo restic-aws restore latest /path/to/restore

# Restore specific backup (using snapshot ID)
sudo restic-aws restore 1a2b3c4d /path/to/restore

# Check repository health
sudo restic-aws check

# Show help
sudo restic-aws help
```

### Scheduling

Backups are scheduled to run daily at 2:00 AM by default.

To modify the schedule:
```sh
sudo systemctl edit restic-backup.timer
```

Example for running every 6 hours:
```
[Timer]
OnCalendar=
OnUnitActiveSec=6h
```

## AWS Infrastructure Setup

If you already have an S3 bucket, you can use it directly. For optimal setup including proper permissions and lifecycle policies, use the included Terraform configuration:

```sh
cd terraform
./setup.sh
```

This creates:
1. S3 bucket with proper security settings
2. Lifecycle rules for Glacier transitions
3. IAM user with minimal permissions
4. Encryption configuration

### Manual AWS Setup

If you prefer to set up AWS resources manually:

1. Create an S3 bucket in your preferred region
2. Create an IAM user with these permissions:
   ```json
   {
       "Version": "2012-10-17",
       "Statement": [
           {
               "Effect": "Allow",
               "Action": [
                   "s3:ListBucket",
                   "s3:GetBucketLocation"
               ],
               "Resource": "arn:aws:s3:::your-bucket-name"
           },
           {
               "Effect": "Allow",
               "Action": [
                   "s3:PutObject",
                   "s3:GetObject",
                   "s3:DeleteObject"
               ],
               "Resource": "arn:aws:s3:::your-bucket-name/*"
           }
       ]
   }
   ```
3. Create access keys for this user
4. Enable default encryption on the bucket
5. Configure lifecycle rules:
   - Transition to Glacier after 30 days
   - Transition to Deep Archive after 90 days (optional)

## Retention Policy

The script automatically manages your backup lifecycle:

- Keeps the last 7 daily backups (default)
- Keeps the last 4 weekly backups (default)
- Keeps the last 3 monthly backups (default)
- Keeps yearly backups if configured
- Automatically removes other snapshots to save space

To customize retention, edit the variables in the configuration file:
```sh
KEEP_DAILY=7
KEEP_WEEKLY=4
KEEP_MONTHLY=3
KEEP_YEARLY=1
```

## Security

### Encryption

All backups are encrypted before leaving your system using:
- AES-256 encryption
- Password-based key derivation

### Password Management

Your backup password is:
1. Generated during installation (a strong random password)
2. Stored securely in `/etc/restic-aws-backup/restic-aws.conf` as BACKUP_PASSWORD
3. Protected with file permissions (only readable by root, chmod 600)

**Important**: Keep a copy of your password somewhere safe. If you lose it, you cannot recover your backups.

### AWS Security

- S3 buckets use server-side encryption (AES-256)
- IAM permissions follow the principle of least privilege
- No public access to your backup bucket
- Data is encrypted before transmission to AWS

## Advanced Configuration

### Bandwidth Limiting

To limit bandwidth usage, add to your configuration file:
```sh
# Bandwidth limit in KiB/s (5120 = 5 MiB/s)
BANDWIDTH_LIMIT=5120
```

### Compression

Enable compression for certain file types:
```sh
# Options: off, auto, max
COMPRESSION=auto
```

### Email Notifications

To receive notifications (requires mailx to be installed):
```sh
# Enable email notifications
ENABLE_NOTIFICATIONS=true
NOTIFICATION_EMAIL="your@email.com"
```

## Troubleshooting

### Common Issues

**Backup fails with access denied**
- Check AWS credentials in configuration file
- Verify IAM permissions on the bucket
- Ensure bucket name is correct and you have access to it

**Unable to connect to repository**
- Check internet connectivity
- Verify bucket name and region are correct
- Test AWS connectivity with another tool

**Restore fails**
- Use `sudo restic-aws snapshots` to list available backups
- Verify the snapshot ID exists
- Ensure target directory is writable

**Password error**
- Ensure BACKUP_PASSWORD in configuration file matches the one used to create repository
- Check file permissions on the configuration file

### Logs

- Check systemd logs: `journalctl -u restic-backup`
- Check script logs: `/var/log/restic-backup.log` (if enabled)

## Uninstallation

```sh
# Stop scheduled backups
sudo systemctl stop restic-backup.timer
sudo systemctl disable restic-backup.timer

# Remove configuration
sudo rm -rf /etc/restic-aws-backup
sudo rm -f /usr/local/bin/restic-aws
sudo rm /etc/systemd/system/restic-backup.*
sudo systemctl daemon-reload

# Optional: Remove restic
sudo apt remove restic  # For Debian/Ubuntu
# or
sudo yum remove restic  # For CentOS/RHEL
```

## Project Structure

The Restic AWS Backup project has been simplified to the following structure:

```
restic-aws-backup/
├── README.md           # Comprehensive documentation (this file)
├── restic-aws.sh       # Main all-in-one script
├── terraform/          # AWS infrastructure setup
│   ├── main.tf         # Main Terraform configuration
│   ├── variables.tf    # Input variables
│   ├── setup.sh        # Infrastructure setup script
│   └── modules/        # Reusable Terraform modules
│       └── s3-backup/  # S3 bucket with lifecycle config
└── test/               # Test suite
    ├── run_tests.sh    # Test runner
    ├── test_restic_aws.sh  # Main script tests
    └── test_terraform.sh   # Terraform validation
```

The project structure has been simplified by:
1. Using a single comprehensive README instead of multiple documentation files
2. Consolidating the client and scripts directories into a single main script
3. Adding a test directory for validation
4. Maintaining the Terraform configuration for AWS infrastructure setup

## Testing

Run the test suite to verify functionality:
```sh
cd test
./run_tests.sh
```

The tests validate:
- Script syntax and structure
- Core functionality without making actual AWS calls
- Configuration file creation and parsing
- Terraform configuration validation

## Terraform Infrastructure

### Terraform Configuration

The Terraform configuration creates all required AWS resources for the backup solution:

#### Resources Created

- **S3 Bucket**: For storing backup data with proper configurations
  - Versioning enabled
  - Server-side encryption
  - Public access blocked
  - Lifecycle rules for cost-effective storage tiers

- **IAM User**: With restricted permissions for backup operations
  - Limited to specific bucket access
  - No administrative privileges

#### Input Variables

| Name | Description | Default |
|------|-------------|---------|
| aws_region | AWS region for resources | us-east-1 |
| s3_bucket_name | S3 bucket name (empty for auto-generated) | "" |
| environment | Environment tag (dev, staging, prod) | "prod" |
| days_until_glacier | Days before transition to Glacier | 30 |
| enable_deep_archive | Whether to use Deep Archive | false |
| days_until_deep_archive | Days before Deep Archive transition | 90 |
| enable_expiration | Whether to expire objects | false |
| days_until_expiration | Days before expiration | 365 |

#### Outputs

| Name | Description |
|------|-------------|
| bucket_name | S3 bucket name |
| aws_access_key | AWS access key for restic |
| aws_secret_key | AWS secret key for restic |
| backup_user_name | Name of the IAM user created |

### S3 Bucket Lifecycle Configuration

The AWS S3 bucket is configured with lifecycle rules to optimize storage costs:

1. **Standard Storage**: For recent backups (first 30 days)
2. **Glacier Storage**: For older backups (after 30 days)
3. **Deep Archive** (Optional): For long-term archival (after 90 days)
4. **Expiration** (Optional): Can be configured to delete very old backups

This tiered approach offers an optimal balance between access speed and cost:
- Quick access to recent backups
- Cost-effective storage for older backups
- Ultra-low cost for archive data

### Manual Terraform Usage

If you prefer not to use the setup script:

```bash
# Initialize
cd terraform
terraform init

# Plan changes
terraform plan -var="aws_region=us-west-2" -var="s3_bucket_name=my-backups"

# Apply changes
terraform apply -var="aws_region=us-west-2" -var="s3_bucket_name=my-backups"

# View outputs (credentials)
terraform output
```

## License

MIT License

---

Based on [Restic](https://restic.net/)