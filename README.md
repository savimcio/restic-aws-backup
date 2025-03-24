# Restic AWS Backup

A simple backup solution for Linux/Unix systems using [Restic](https://restic.net/) and AWS S3/Glacier. This project provides an encrypted backup solution with cost-optimized storage.

## Features

- **Simple Setup**: Minimal configuration required
- **Encrypted Backups**: End-to-end encryption
- **AWS S3 + Glacier**: Cost-effective storage with lifecycle rules
- **Automated**: Daily scheduled backups
- **Retention Policies**: Manages backup lifecycle
- **Deduplication**: Saves storage space

## Requirements

- Linux/Unix system with sudo access
- AWS account with credentials
- Internet connection

## Setup Overview

1. Set up AWS infrastructure (S3 bucket and IAM permissions)
2. Install and configure the backup client
3. Run your first backup

## AWS Infrastructure Setup

### Using Terraform (Recommended)

```sh
# Clone the repository
git clone https://github.com/savimcio/restic-aws-backup.git
cd restic-aws-backup/terraform

# Run setup script
./setup.sh
```

The script will:
1. Create an S3 bucket with proper security settings
2. Set up lifecycle rules for Glacier transitions
3. Create an IAM user with minimal permissions
4. Configure server-side encryption
5. Save credentials to `~/.restic-aws-backup/config`

### Manual AWS Setup

1. Create an S3 bucket
2. Create an IAM user with these permissions:
   ```json
   {
       "Version": "2012-10-17",
       "Statement": [
           {
               "Effect": "Allow",
               "Action": ["s3:ListBucket", "s3:GetBucketLocation"],
               "Resource": "arn:aws:s3:::your-bucket-name"
           },
           {
               "Effect": "Allow",
               "Action": ["s3:PutObject", "s3:GetObject", "s3:DeleteObject"],
               "Resource": "arn:aws:s3:::your-bucket-name/*"
           }
       ]
   }
   ```
3. Configure lifecycle rules (optional):
   - Transition to Glacier after 30 days
   - Transition to Deep Archive after 90 days (optional)

## Client Installation

```sh
# Download the script
curl -s https://raw.githubusercontent.com/savimcio/restic-aws-backup/main/restic-aws.sh -o restic-aws.sh
chmod +x restic-aws.sh

# Install
sudo ./restic-aws.sh install
```

The install process:
1. Installs restic
2. Creates configuration directories
3. Sets up systemd service for daily backups at 2:00 AM
4. Generates a secure password

## Configuration

Configure AWS settings:

```sh
sudo ./restic-aws.sh configure
```

You'll be prompted for:
- AWS Access Key ID
- AWS Secret Access Key
- S3 Bucket Name
- AWS Region
- Directories to back up
- Retention policy settings

Settings are stored in `/etc/restic-aws-backup/restic-aws.conf`

## Usage

```sh
# Run backup manually
sudo restic-aws backup

# List backups
sudo restic-aws snapshots

# Restore latest backup
sudo restic-aws restore latest /path/to/restore

# Restore specific backup
sudo restic-aws restore 1a2b3c4d /path/to/restore

# Check repository health
sudo restic-aws check

# Show help
sudo restic-aws help
```

## Retention Policy

Default backup retention:
- Last 7 daily backups
- Last 4 weekly backups
- Last 3 monthly backups

To customize, edit in the configuration file:
```sh
KEEP_DAILY=7
KEEP_WEEKLY=4
KEEP_MONTHLY=3
```

## Security

- AES-256 client-side encryption
- Password stored securely (only readable by root)
- S3 server-side encryption
- Least-privilege IAM permissions

**Important**: Keep a copy of your password in a secure location.

## Advanced Configuration

### Bandwidth Limiting

```sh
# Add to config file (5120 = 5 MiB/s)
BANDWIDTH_LIMIT=5120
```

### Compression

```sh
# Add to config file (options: off, auto, max)
COMPRESSION=auto
```

## Troubleshooting

**Backup fails with access denied**
- Check AWS credentials
- Verify IAM permissions
- Confirm bucket name is correct

**Unable to connect to repository**
- Check internet connection
- Verify bucket name and region

**Logs**
- Check systemd logs: `journalctl -u restic-backup`

## Uninstallation

```sh
# Stop and disable service
sudo systemctl stop restic-backup.timer
sudo systemctl disable restic-backup.timer

# Remove files
sudo rm -rf /etc/restic-aws-backup
sudo rm -f /usr/local/bin/restic-aws
sudo rm /etc/systemd/system/restic-backup.*
sudo systemctl daemon-reload

# Optional: Remove restic package
sudo apt remove restic  # Debian/Ubuntu
# or
sudo yum remove restic  # CentOS/RHEL
```

## Project Structure

```
restic-aws-backup/
├── README.md           # Documentation
├── restic-aws.sh       # Main script
├── terraform/          # AWS infrastructure setup
│   ├── main.tf         # Terraform configuration
│   ├── variables.tf    # Input variables
│   ├── setup.sh        # Setup script
│   └── modules/        # Terraform modules
└── test/               # Test suite
```

## Testing

```sh
cd test
./run_tests.sh
```

## License

MIT License

---

Based on [Restic](https://restic.net/)