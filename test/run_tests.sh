#!/bin/bash
# Master test runner for Restic AWS Backup
# Runs all available tests in sequence

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}=====================================${NC}"
echo -e "${BLUE}  Restic AWS Backup Test Suite      ${NC}"
echo -e "${BLUE}=====================================${NC}"

# Get the directory of this script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
cd "$SCRIPT_DIR"

# Define test files to run
TEST_FILES=(
  "test_restic_aws.sh"
  "test_terraform.sh"
)

# Track test results
TOTAL_TESTS=${#TEST_FILES[@]}
PASSED=0
FAILED=0

# Run each test file
for test_file in "${TEST_FILES[@]}"; do
  echo -e "\n${YELLOW}Running test: ${test_file}${NC}"
  echo -e "${YELLOW}------------------------------------${NC}"
  
  if [ -f "$test_file" ] && [ -x "$test_file" ]; then
    # Run the test file
    if ./"$test_file"; then
      echo -e "\n${GREEN}✓ Test passed: ${test_file}${NC}"
      PASSED=$((PASSED + 1))
    else
      echo -e "\n${RED}✗ Test failed: ${test_file}${NC}"
      FAILED=$((FAILED + 1))
    fi
  else
    echo -e "${RED}✗ Test file not found or not executable: ${test_file}${NC}"
    FAILED=$((FAILED + 1))
  fi
  
  echo -e "${YELLOW}------------------------------------${NC}"
done

# Print summary
echo -e "\n${BLUE}=====================================${NC}"
echo -e "${BLUE}  Test Summary                      ${NC}"
echo -e "${BLUE}=====================================${NC}"
echo -e "Total tests:  $TOTAL_TESTS"
echo -e "${GREEN}Tests passed: $PASSED${NC}"
echo -e "${RED}Tests failed: $FAILED${NC}"

# Exit with appropriate status code
if [ $FAILED -eq 0 ]; then
  echo -e "\n${GREEN}All tests passed!${NC}"
  exit 0
else
  echo -e "\n${RED}Some tests failed!${NC}"
  exit 1
fi