#!/bin/bash
# AWS S3 and IAM setup script for Restic AWS Backup
# Creates S3 bucket and IAM user with appropriate permissions

set -e  # Exit on error

echo "==== Restic AWS Backup Infrastructure Setup ===="

# Check for required tools
command -v aws >/dev/null 2>&1 || { echo "Error: AWS CLI is required but not installed. Please install it first."; exit 1; }
command -v terraform >/dev/null 2>&1 || { echo "Error: Terraform is required but not installed. Please install it first."; exit 1; }

# Check AWS credentials
if ! aws sts get-caller-identity &>/dev/null; then
  echo "Error: AWS credentials not configured."
  echo "Please configure AWS credentials using one of these methods:"
  echo "  1. Run 'aws configure'"
  echo "  2. Set AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY environment variables"
  echo "  3. Use an EC2 instance role or credential provider"
  exit 1
fi

# Allow customization through environment variables or prompt user
if [ -z "$AWS_REGION" ]; then
  read -p "Enter AWS region [default: us-east-1]: " AWS_REGION
  AWS_REGION="${AWS_REGION:-us-east-1}"
else
  echo "Using AWS region: $AWS_REGION"
fi

if [ -z "$S3_BUCKET_NAME" ]; then
  DEFAULT_BUCKET="restic-backup-$(date +%Y%m%d)"
  read -p "Enter S3 bucket name [default: $DEFAULT_BUCKET]: " S3_BUCKET_NAME
  S3_BUCKET_NAME="${S3_BUCKET_NAME:-$DEFAULT_BUCKET}"
else
  echo "Using S3 bucket name: $S3_BUCKET_NAME"
fi

if [ -z "$ENVIRONMENT" ]; then
  read -p "Enter environment (dev, staging, prod) [default: prod]: " ENVIRONMENT
  ENVIRONMENT="${ENVIRONMENT:-prod}"
else
  echo "Using environment: $ENVIRONMENT"
fi

# Glacier and lifecycle options
echo
echo "Storage Lifecycle Configuration"
read -p "Days until objects transition to Glacier [default: 30]: " DAYS_GLACIER
DAYS_GLACIER="${DAYS_GLACIER:-30}"

read -p "Enable transition to Deep Archive? (y/N): " ENABLE_DEEP_ARCHIVE
if [[ "$ENABLE_DEEP_ARCHIVE" =~ ^[Yy] ]]; then
  ENABLE_DEEP_ARCHIVE="true"
  read -p "Days until objects transition to Deep Archive [default: 90]: " DAYS_DEEP_ARCHIVE
  DAYS_DEEP_ARCHIVE="${DAYS_DEEP_ARCHIVE:-90}"
else
  ENABLE_DEEP_ARCHIVE="false"
  DAYS_DEEP_ARCHIVE="90"
fi

read -p "Enable object expiration? (y/N): " ENABLE_EXPIRATION
if [[ "$ENABLE_EXPIRATION" =~ ^[Yy] ]]; then
  ENABLE_EXPIRATION="true"
  read -p "Days until objects are deleted [default: 365]: " DAYS_EXPIRATION
  DAYS_EXPIRATION="${DAYS_EXPIRATION:-365}"
else
  ENABLE_EXPIRATION="false"
  DAYS_EXPIRATION="365"
fi

echo
echo "Setting up infrastructure with the following configuration:"
echo "  - AWS Region: $AWS_REGION"
echo "  - S3 Bucket: $S3_BUCKET_NAME"
echo "  - Environment: $ENVIRONMENT"
echo "  - Glacier transition: after $DAYS_GLACIER days"
if [ "$ENABLE_DEEP_ARCHIVE" = "true" ]; then
  echo "  - Deep Archive transition: after $DAYS_DEEP_ARCHIVE days"
fi
if [ "$ENABLE_EXPIRATION" = "true" ]; then
  echo "  - Object expiration: after $DAYS_EXPIRATION days"
fi
echo

# Confirm before proceeding
read -p "Proceed with installation? [Y/n]: " CONFIRM
CONFIRM="${CONFIRM:-Y}"
if [[ ! "$CONFIRM" =~ ^[Yy] ]]; then
  echo "Installation canceled."
  exit 0
fi

# Initialize and apply Terraform configuration
echo "Initializing Terraform..."
terraform init

echo "Applying Terraform configuration..."
terraform apply -auto-approve \
  -var="aws_region=$AWS_REGION" \
  -var="s3_bucket_name=$S3_BUCKET_NAME" \
  -var="environment=$ENVIRONMENT" \
  -var="days_until_glacier=$DAYS_GLACIER" \
  -var="enable_deep_archive=$ENABLE_DEEP_ARCHIVE" \
  -var="days_until_deep_archive=$DAYS_DEEP_ARCHIVE" \
  -var="enable_expiration=$ENABLE_EXPIRATION" \
  -var="days_until_expiration=$DAYS_EXPIRATION" || { echo "Terraform apply failed"; exit 1; }

# Extract and create configuration file
BUCKET_NAME=$(terraform output -raw bucket_name)
AWS_ACCESS_KEY=$(terraform output -raw aws_access_key)
AWS_SECRET_KEY=$(terraform output -raw aws_secret_key)

CONFIG_DIR="$HOME/.restic-aws-backup"
mkdir -p "$CONFIG_DIR"
CONFIG_FILE="$CONFIG_DIR/config"

cat > "$CONFIG_FILE" << EOF
# Restic AWS Backup Configuration
# Created $(date)
BUCKET_NAME=$BUCKET_NAME
AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY
AWS_SECRET_ACCESS_KEY=$AWS_SECRET_KEY
AWS_REGION=$AWS_REGION
EOF

chmod 600 "$CONFIG_FILE"

# Extract and display important outputs
echo
echo "==== Infrastructure setup complete ===="
echo "---------------------------------------"
echo "S3 Bucket: $BUCKET_NAME"
echo "AWS Access Key: $AWS_ACCESS_KEY"
echo "AWS Secret Key: $AWS_SECRET_KEY"
echo "---------------------------------------"
echo
echo "IMPORTANT: Configuration saved to $CONFIG_FILE"
echo "You can now run the following to set up a client:"
echo 
echo "curl -s https://raw.githubusercontent.com/msavitskyi/restic-aws-backup/main/install.sh | sudo bash"
echo
echo "When prompted, you can use the values from $CONFIG_FILE"