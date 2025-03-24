#!/bin/bash
# MIT License
# Copyright (c) 2025 savimcio
#
# Permission is hereby granted, free of charge, to any person obtaining a copy
# of this software and associated documentation files (the "Software"), to deal
# in the Software without restriction, including without limitation the rights
# to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
# copies of the Software, and to permit persons to whom the Software is
# furnished to do so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#
# Restic AWS Backup - All-in-one script for install, configure and backup
# Usage: sudo ./restic-aws.sh [install|backup|configure]

set -e

# Single configuration file
CONFIG_DIR="/etc/restic-aws-backup"
CONFIG_FILE="$CONFIG_DIR/restic-aws.conf"

# Default configuration values
DEFAULT_PATHS="/home,/etc"
DEFAULT_EXCLUDES=".cache/,.tmp/,/proc/,/sys/,/dev/,/run/,/var/run/,/var/cache/,*.log"

# Helper function for logging
log() {
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $1"
}

# Check if running as root
check_root() {
  if [ "$(id -u)" -ne 0 ]; then
    echo "Error: This script must be run as root"
    echo "Please run: sudo $0 $1"
    exit 1
  fi
}

# Install restic and setup environment
install_restic() {
  check_root "install"
  log "Installing restic and setting up environment..."
  
  # Create configuration directory
  mkdir -p "$CONFIG_DIR"
  
  # Install restic based on package manager
  if command -v apt &> /dev/null; then
    apt update && apt install -y restic
  elif command -v yum &> /dev/null; then
    yum install -y restic
  elif command -v dnf &> /dev/null; then
    dnf install -y restic
  elif command -v pacman &> /dev/null; then
    pacman -Sy --noconfirm restic
  else
    log "Error: Unable to detect package manager. Please install restic manually."
    exit 1
  fi
  
  # Generate a secure backup password
  PASSWORD=$(tr -dc 'A-Za-z0-9!@#$%^&*' < /dev/urandom | head -c 32)
  
  # Create initial configuration file
  cat > "$CONFIG_FILE" << EOF
# Restic AWS Backup Configuration
# Generated on $(date)

# AWS Credentials - Configure these with 'restic-aws configure'
AWS_ACCESS_KEY_ID=
AWS_SECRET_ACCESS_KEY=
BUCKET_NAME=
AWS_REGION=us-east-1

# Backup Settings
BACKUP_PASSWORD=$PASSWORD
BACKUP_PATHS="$DEFAULT_PATHS"

# Retention Policy
KEEP_DAILY=7
KEEP_WEEKLY=4
KEEP_MONTHLY=3

# Files/directories to exclude (comma-separated)
EXCLUDE_PATTERNS="$DEFAULT_EXCLUDES"
EOF

  chmod 600 "$CONFIG_FILE"
  log "Created configuration file at $CONFIG_FILE"
  log "IMPORTANT: Your backup password is: $PASSWORD"
  log "Save this password securely! You'll need it for restores."
  
  # Create systemd service for scheduled backups
  cat > /etc/systemd/system/restic-backup.service << EOF
[Unit]
Description=Restic AWS Backup
After=network-online.target

[Service]
Type=oneshot
ExecStart=/bin/bash $0 backup
EOF

  # Create systemd timer to run backups daily at 2am
  cat > /etc/systemd/system/restic-backup.timer << EOF
[Unit]
Description=Daily Restic AWS Backup

[Timer]
OnCalendar=*-*-* 02:00:00
RandomizedDelaySec=1800
Persistent=true

[Install]
WantedBy=timers.target
EOF

  # Enable and start timer
  systemctl daemon-reload
  systemctl enable restic-backup.timer
  systemctl start restic-backup.timer
  
  # Create symlink for easy access
  ln -sf "$0" /usr/local/bin/restic-aws
  
  log "Installation complete. Please run 'sudo $0 configure' to set up AWS credentials."
}

# Configure AWS settings
configure_aws() {
  check_root "configure"
  log "Configuring AWS settings..."
  
  # Read existing configuration
  if [ -f "$CONFIG_FILE" ]; then
    source "$CONFIG_FILE"
  else
    log "Error: Configuration file not found. Please run 'sudo $0 install' first."
    exit 1
  fi
  
  # Prompt for AWS settings
  read -p "Enter AWS Access Key ID: " NEW_AWS_ACCESS_KEY
  read -p "Enter AWS Secret Access Key: " NEW_AWS_SECRET_KEY
  read -p "Enter S3 Bucket Name: " NEW_BUCKET_NAME
  read -p "Enter AWS Region [${AWS_REGION:-us-east-1}]: " NEW_AWS_REGION
  NEW_AWS_REGION="${NEW_AWS_REGION:-${AWS_REGION:-us-east-1}}"
  
  # Prompt for backup paths
  read -p "Enter backup paths (comma separated) [${BACKUP_PATHS:-$DEFAULT_PATHS}]: " NEW_BACKUP_PATHS
  NEW_BACKUP_PATHS="${NEW_BACKUP_PATHS:-${BACKUP_PATHS:-$DEFAULT_PATHS}}"
  
  # Prompt for retention policy
  read -p "Number of daily backups to keep [${KEEP_DAILY:-7}]: " NEW_KEEP_DAILY
  NEW_KEEP_DAILY="${NEW_KEEP_DAILY:-${KEEP_DAILY:-7}}"
  
  read -p "Number of weekly backups to keep [${KEEP_WEEKLY:-4}]: " NEW_KEEP_WEEKLY
  NEW_KEEP_WEEKLY="${NEW_KEEP_WEEKLY:-${KEEP_WEEKLY:-4}}"
  
  read -p "Number of monthly backups to keep [${KEEP_MONTHLY:-3}]: " NEW_KEEP_MONTHLY
  NEW_KEEP_MONTHLY="${NEW_KEEP_MONTHLY:-${KEEP_MONTHLY:-3}}"
  
  # Store the config values
  sed -i.bak "s|^AWS_ACCESS_KEY_ID=.*|AWS_ACCESS_KEY_ID=$NEW_AWS_ACCESS_KEY|" "$CONFIG_FILE"
  sed -i.bak "s|^AWS_SECRET_ACCESS_KEY=.*|AWS_SECRET_ACCESS_KEY=$NEW_AWS_SECRET_KEY|" "$CONFIG_FILE"
  sed -i.bak "s|^BUCKET_NAME=.*|BUCKET_NAME=$NEW_BUCKET_NAME|" "$CONFIG_FILE"
  sed -i.bak "s|^AWS_REGION=.*|AWS_REGION=$NEW_AWS_REGION|" "$CONFIG_FILE"
  sed -i.bak "s|^BACKUP_PATHS=.*|BACKUP_PATHS=\"$NEW_BACKUP_PATHS\"|" "$CONFIG_FILE"
  sed -i.bak "s|^KEEP_DAILY=.*|KEEP_DAILY=$NEW_KEEP_DAILY|" "$CONFIG_FILE"
  sed -i.bak "s|^KEEP_WEEKLY=.*|KEEP_WEEKLY=$NEW_KEEP_WEEKLY|" "$CONFIG_FILE"
  sed -i.bak "s|^KEEP_MONTHLY=.*|KEEP_MONTHLY=$NEW_KEEP_MONTHLY|" "$CONFIG_FILE"
  
  # Remove backup file
  rm -f "${CONFIG_FILE}.bak"
  
  log "Configuration updated successfully at $CONFIG_FILE"
  log "Run 'sudo $0 backup' to perform a backup."
}

# Run backup to AWS
run_backup() {
  check_root "backup"
  
  # Check if configuration exists
  if [ ! -f "$CONFIG_FILE" ]; then
    log "Error: Configuration not found. Please run 'sudo $0 install' and 'sudo $0 configure' first."
    exit 1
  fi
  
  # Load configuration
  source "$CONFIG_FILE"
  
  # Check required values
  if [ -z "$AWS_ACCESS_KEY_ID" ] || [ -z "$AWS_SECRET_ACCESS_KEY" ] || [ -z "$BUCKET_NAME" ]; then
    log "Error: Missing required AWS settings. Please run 'sudo $0 configure' to set them up."
    exit 1
  fi
  
  if [ -z "$BACKUP_PASSWORD" ]; then
    log "Error: Backup password not set in configuration. Please run 'sudo $0 install' again."
    exit 1
  fi
  
  # Create temporary files for password and excludes
  TEMP_DIR=$(mktemp -d)
  TEMP_PASSWORD_FILE="$TEMP_DIR/password"
  TEMP_EXCLUDE_FILE="$TEMP_DIR/excludes"
  
  # Write password to temp file
  echo "$BACKUP_PASSWORD" > "$TEMP_PASSWORD_FILE"
  chmod 600 "$TEMP_PASSWORD_FILE"
  
  # Create excludes file from comma-separated patterns in config
  if [ -n "$EXCLUDE_PATTERNS" ]; then
    # Convert comma-separated list to lines
    echo "$EXCLUDE_PATTERNS" | tr ',' '\n' > "$TEMP_EXCLUDE_FILE"
    EXCLUDE_ARGS="--exclude-file=$TEMP_EXCLUDE_FILE"
  else
    EXCLUDE_ARGS=""
  fi
  
  # Set up restic environment
  export RESTIC_REPOSITORY="s3:s3.amazonaws.com/$BUCKET_NAME"
  export RESTIC_PASSWORD_FILE="$TEMP_PASSWORD_FILE"
  export AWS_ACCESS_KEY_ID
  export AWS_SECRET_ACCESS_KEY
  export AWS_REGION="${AWS_REGION:-us-east-1}"
  
  # Initialize repository if needed
  if ! restic snapshots &>/dev/null; then
    log "Initializing repository..."
    restic init || { log "Failed to initialize repository"; rm -rf "$TEMP_DIR"; exit 1; }
  fi
  
  # Get hostname for backup identification
  HOSTNAME=$(hostname)
  TIMESTAMP=$(date +%Y-%m-%d_%H-%M-%S)
  
  # Run backup
  log "Starting backup of $BACKUP_PATHS"
  
  # Convert comma-separated paths to space-separated for restic
  PATHS_FOR_RESTIC=$(echo "$BACKUP_PATHS" | tr ',' ' ')
  
  restic backup $PATHS_FOR_RESTIC \
    --verbose \
    --tag "$HOSTNAME" \
    --tag "automated" \
    --tag "timestamp-$TIMESTAMP" \
    $EXCLUDE_ARGS || { log "Backup failed"; rm -rf "$TEMP_DIR"; exit 1; }
  
  # Prune old backups based on retention policy
  log "Pruning old backups..."
  restic forget --prune \
    --keep-daily ${KEEP_DAILY:-7} \
    --keep-weekly ${KEEP_WEEKLY:-4} \
    --keep-monthly ${KEEP_MONTHLY:-3} || { log "Pruning failed"; rm -rf "$TEMP_DIR"; exit 1; }
  
  # Clean up temp directory
  rm -rf "$TEMP_DIR"
  
  log "Backup completed successfully"
}

# Print help message
show_help() {
  echo "Restic AWS Backup - Simple AWS S3 backup solution"
  echo ""
  echo "Usage: sudo $0 [command]"
  echo ""
  echo "Commands:"
  echo "  install     Install restic and set up scheduled backups"
  echo "  configure   Configure AWS credentials and backup paths"
  echo "  backup      Run backup manually"
  echo "  snapshots   List all backup snapshots"
  echo "  restore     Restore from backup (e.g. $0 restore latest /target)"
  echo "  check       Check backup repository integrity"
  echo "  help        Show this help message"
  echo ""
  echo "Examples:"
  echo "  sudo $0 install           # Install restic and set up backups"
  echo "  sudo $0 configure         # Configure AWS credentials"
  echo "  sudo $0 backup            # Run backup manually"
  echo "  sudo $0 restore latest /  # Restore latest backup to /"
}

# Set up common restic environment
setup_restic_env() {
  # Check if configuration exists
  if [ ! -f "$CONFIG_FILE" ]; then
    log "Error: Configuration not found. Please run 'sudo $0 install' and 'sudo $0 configure' first."
    exit 1
  fi
  
  # Load configuration
  source "$CONFIG_FILE"
  
  # Check required values
  if [ -z "$AWS_ACCESS_KEY_ID" ] || [ -z "$AWS_SECRET_ACCESS_KEY" ] || [ -z "$BUCKET_NAME" ]; then
    log "Error: Missing required AWS settings. Please run 'sudo $0 configure' to set them up."
    exit 1
  fi
  
  if [ -z "$BACKUP_PASSWORD" ]; then
    log "Error: Backup password not set in configuration. Please run 'sudo $0 install' again."
    exit 1
  fi
  
  # Create temporary password file
  TEMP_DIR=$(mktemp -d)
  TEMP_PASSWORD_FILE="$TEMP_DIR/password"
  
  # Write password to temp file
  echo "$BACKUP_PASSWORD" > "$TEMP_PASSWORD_FILE"
  chmod 600 "$TEMP_PASSWORD_FILE"
  
  # Set up restic environment
  export RESTIC_REPOSITORY="s3:s3.amazonaws.com/$BUCKET_NAME"
  export RESTIC_PASSWORD_FILE="$TEMP_PASSWORD_FILE"
  export AWS_ACCESS_KEY_ID
  export AWS_SECRET_ACCESS_KEY
  export AWS_REGION="${AWS_REGION:-us-east-1}"
  
  # Return temp dir path for later cleanup
  echo "$TEMP_DIR"
}

# Restore backup
restore_backup() {
  check_root "restore"
  
  if [ -z "$2" ] || [ -z "$3" ]; then
    log "Error: Restore requires snapshot ID and target path"
    echo "Usage: $0 restore <snapshot-id> <target-path>"
    exit 1
  fi
  
  SNAPSHOT="$2"
  TARGET="$3"
  
  # Setup environment
  TEMP_DIR=$(setup_restic_env)
  
  log "Restoring snapshot $SNAPSHOT to $TARGET..."
  restic restore "$SNAPSHOT" --target "$TARGET" "${@:4}"
  RESULT=$?
  
  # Clean up
  rm -rf "$TEMP_DIR"
  
  if [ $RESULT -eq 0 ]; then
    log "Restore completed successfully"
  else
    log "Restore failed"
    exit 1
  fi
}

# List snapshots
list_snapshots() {
  check_root "snapshots"
  
  # Setup environment
  TEMP_DIR=$(setup_restic_env)
  
  restic snapshots
  RESULT=$?
  
  # Clean up
  rm -rf "$TEMP_DIR"
  
  exit $RESULT
}

# Check repository
check_repo() {
  check_root "check"
  
  # Setup environment
  TEMP_DIR=$(setup_restic_env)
  
  log "Checking repository integrity..."
  restic check
  RESULT=$?
  
  # Clean up
  rm -rf "$TEMP_DIR"
  
  if [ $RESULT -eq 0 ]; then
    log "Repository check completed successfully"
  else
    log "Repository check found issues"
    exit 1
  fi
}

# Process command line arguments
case "$1" in
  install)
    install_restic
    ;;
  configure)
    configure_aws
    ;;
  backup)
    run_backup
    ;;
  snapshots)
    list_snapshots
    ;;
  restore)
    restore_backup "$@"
    ;;
  check)
    check_repo
    ;;
  help|--help|-h)
    show_help
    ;;
  *)
    show_help
    ;;
esac