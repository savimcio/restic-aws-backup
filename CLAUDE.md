# Restic AWS Backup - Claude Guide

## Build/Test Commands
- Run all tests: `cd test && ./run_tests.sh`
- Run specific test: `cd test && ./test_restic_aws.sh` or `./test_terraform.sh`
- Terraform validation: `cd terraform && terraform validate`
- Bash script syntax check: `bash -n restic-aws.sh`

## Code Style Guidelines

### Shell Scripts
- Use `#!/bin/bash` shebang with `set -e` for error handling
- Functions are snake_case with clear descriptive names
- Log with timestamp using the `log()` helper function
- Check for root privileges before privileged operations
- Document functions with comments above definition

### Terraform
- 2-space indentation
- Use modules for reusable components
- Document all variables and outputs with descriptions
- Mark sensitive outputs as `sensitive = true`
- Use locals for computed values
- Follow a consistent naming scheme for resources

### Error Handling
- Exit with non-zero status on errors
- Use meaningful error messages with instruction for resolution
- Clean up temporary files in all exit paths

### Security
- Store credentials securely with proper file permissions (chmod 600)
- Use temporary files for secrets, cleaned up after use
- Follow least privilege principle for AWS permissions