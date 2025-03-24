#!/bin/bash
# Test script for Terraform configuration
# This script validates Terraform files without making actual AWS changes

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}===== Terraform Configuration Test =====${NC}"

# Change to the terraform directory
TERRAFORM_DIR="../terraform"
cd $TERRAFORM_DIR

# Test 1: Check if terraform files exist
echo -e "\n${YELLOW}Test 1: Terraform files exist${NC}"
REQUIRED_FILES=("main.tf" "variables.tf" "modules/s3-backup/main.tf" "modules/s3-backup/variables.tf")
MISSING=0

for file in "${REQUIRED_FILES[@]}"; do
  if [ -f "$file" ]; then
    echo -e "${GREEN}PASS: File '$file' found${NC}"
  else
    echo -e "${RED}FAIL: File '$file' not found${NC}"
    MISSING=$((MISSING + 1))
  fi
done

if [ $MISSING -eq 0 ]; then
  echo -e "${GREEN}All required Terraform files present${NC}"
else
  echo -e "${RED}Missing $MISSING required files${NC}"
  exit 1
fi

# Test 2: Terraform validation if terraform is installed
echo -e "\n${YELLOW}Test 2: Terraform validation${NC}"
if command -v terraform &> /dev/null; then
  echo "Initializing Terraform in test mode..."
  terraform init -backend=false
  
  echo "Validating Terraform configuration..."
  terraform validate
  
  if [ $? -eq 0 ]; then
    echo -e "${GREEN}PASS: Terraform configuration is valid${NC}"
  else
    echo -e "${RED}FAIL: Terraform configuration is invalid${NC}"
    exit 1
  fi
else
  echo -e "${YELLOW}SKIP: Terraform not installed, skipping validation${NC}"
fi

# Test 3: Check key variables are defined
echo -e "\n${YELLOW}Test 3: Required variables defined${NC}"
REQUIRED_VARS=("aws_region" "s3_bucket_name" "days_until_glacier")
MISSING=0

for var in "${REQUIRED_VARS[@]}"; do
  if grep -q "variable \"$var\"" "variables.tf"; then
    echo -e "${GREEN}PASS: Variable '$var' defined${NC}"
  else
    echo -e "${RED}FAIL: Variable '$var' not defined${NC}"
    MISSING=$((MISSING + 1))
  fi
done

if [ $MISSING -eq 0 ]; then
  echo -e "${GREEN}All required variables defined${NC}"
else
  echo -e "${RED}Missing $MISSING required variables${NC}"
  exit 1
fi

# Test 4: Check required providers and module outputs
echo -e "\n${YELLOW}Test 4: Key configurations present${NC}"
if grep -q "provider \"aws\"" "main.tf"; then
  echo -e "${GREEN}PASS: AWS provider configured${NC}"
else
  echo -e "${RED}FAIL: AWS provider not configured${NC}"
  exit 1
fi

if grep -q "module \"s3_backup\"" "main.tf"; then
  echo -e "${GREEN}PASS: S3 backup module referenced${NC}"
else
  echo -e "${RED}FAIL: S3 backup module not referenced${NC}"
  exit 1
fi

if grep -q "aws_s3_bucket" "modules/s3-backup/main.tf"; then
  echo -e "${GREEN}PASS: S3 bucket resource defined${NC}"
else
  echo -e "${RED}FAIL: S3 bucket resource not defined${NC}"
  exit 1
fi

echo -e "\n${GREEN}All Terraform tests passed!${NC}"