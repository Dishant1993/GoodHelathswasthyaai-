#!/bin/bash
# SwasthyaAI AWS CLI Configuration Validation Script (Bash)
# This script validates AWS CLI profiles and checks connectivity

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
GRAY='\033[0;37m'
NC='\033[0m' # No Color

# Helper functions
print_success() { echo -e "${GREEN}$1${NC}"; }
print_info() { echo -e "${CYAN}$1${NC}"; }
print_warning() { echo -e "${YELLOW}$1${NC}"; }
print_error() { echo -e "${RED}$1${NC}"; }
print_gray() { echo -e "${GRAY}$1${NC}"; }

# Parse command line arguments
PROFILE="all"
VERBOSE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --profile)
            PROFILE="$2"
            shift 2
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--profile <profile-name>] [--verbose]"
            exit 1
            ;;
    esac
done

# Banner
echo -e "${CYAN}"
cat << "EOF"
╔═══════════════════════════════════════════════════════════╗
║     SwasthyaAI AWS CLI Validation Script                  ║
╚═══════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# Check if AWS CLI is installed
print_info "\nChecking AWS CLI installation..."
if command -v aws &> /dev/null; then
    AWS_VERSION=$(aws --version 2>&1)
    print_success "✓ AWS CLI is installed: $AWS_VERSION"
else
    print_error "✗ AWS CLI is not installed!"
    exit 1
fi

# Check if config files exist
AWS_CONFIG_DIR="$HOME/.aws"
CONFIG_FILE="$AWS_CONFIG_DIR/config"
CREDENTIALS_FILE="$AWS_CONFIG_DIR/credentials"

print_info "\nChecking configuration files..."
if [ -f "$CONFIG_FILE" ]; then
    print_success "✓ Config file exists: $CONFIG_FILE"
else
    print_error "✗ Config file not found: $CONFIG_FILE"
    exit 1
fi

if [ -f "$CREDENTIALS_FILE" ]; then
    print_success "✓ Credentials file exists: $CREDENTIALS_FILE"
else
    print_error "✗ Credentials file not found: $CREDENTIALS_FILE"
    exit 1
fi

# Define profiles to test
ALL_PROFILES=(
    "swasthyaai-management"
    "swasthyaai-dev"
    "swasthyaai-staging"
    "swasthyaai-prod"
    "swasthyaai-security"
)

if [ "$PROFILE" = "all" ]; then
    PROFILES_TO_TEST=("${ALL_PROFILES[@]}")
else
    PROFILES_TO_TEST=("swasthyaai-$PROFILE")
fi

# Validation tests
print_info "\nRunning validation tests..."
echo ""

declare -A RESULTS
PASS_COUNT=0
TOTAL_COUNT=${#PROFILES_TO_TEST[@]}

for PROFILE_NAME in "${PROFILES_TO_TEST[@]}"; do
    echo -e "${CYAN}============================================================${NC}"
    echo -e "${YELLOW}Testing Profile: $PROFILE_NAME${NC}"
    echo -e "${CYAN}============================================================${NC}"
    
    PROFILE_STATUS="PASS"
    IDENTITY_STATUS="FAIL"
    REGION_STATUS="FAIL"
    S3_STATUS="FAIL"
    IAM_STATUS="FAIL"
    
    # Test 1: Get caller identity
    print_info "\n[Test 1] Checking AWS identity..."
    if IDENTITY_JSON=$(aws sts get-caller-identity --profile "$PROFILE_NAME" 2>&1); then
        USER_ID=$(echo "$IDENTITY_JSON" | grep -o '"UserId": "[^"]*"' | cut -d'"' -f4)
        ACCOUNT=$(echo "$IDENTITY_JSON" | grep -o '"Account": "[^"]*"' | cut -d'"' -f4)
        ARN=$(echo "$IDENTITY_JSON" | grep -o '"Arn": "[^"]*"' | cut -d'"' -f4)
        
        print_success "  ✓ Identity verified"
        print_gray "    User ID: $USER_ID"
        print_gray "    Account: $ACCOUNT"
        print_gray "    ARN: $ARN"
        IDENTITY_STATUS="PASS"
    else
        print_error "  ✗ Failed to get identity: $IDENTITY_JSON"
        PROFILE_STATUS="FAIL"
    fi
    
    # Test 2: Check region configuration
    print_info "\n[Test 2] Checking region configuration..."
    if REGION=$(aws configure get region --profile "$PROFILE_NAME" 2>&1); then
        if [ -n "$REGION" ]; then
            print_success "  ✓ Region configured: $REGION"
            REGION_STATUS="PASS"
        else
            print_warning "  ⚠ Region not configured or using default"
            REGION_STATUS="WARN"
        fi
    else
        print_warning "  ⚠ Could not determine region"
        REGION_STATUS="WARN"
    fi
    
    # Test 3: Test S3 access
    print_info "\n[Test 3] Testing S3 access..."
    if S3_RESULT=$(aws s3 ls --profile "$PROFILE_NAME" 2>&1); then
        BUCKET_COUNT=$(echo "$S3_RESULT" | wc -l)
        print_success "  ✓ S3 access verified ($BUCKET_COUNT buckets)"
        if [ "$VERBOSE" = true ] && [ -n "$S3_RESULT" ]; then
            print_gray "    Buckets:"
            echo "$S3_RESULT" | while read -r line; do
                print_gray "      $line"
            done
        fi
        S3_STATUS="PASS"
    else
        print_warning "  ⚠ S3 access failed or no buckets"
        S3_STATUS="WARN"
    fi
    
    # Test 4: Test IAM access
    print_info "\n[Test 4] Testing IAM read access..."
    if IAM_RESULT=$(aws iam list-users --max-items 1 --profile "$PROFILE_NAME" 2>&1); then
        print_success "  ✓ IAM read access verified"
        IAM_STATUS="PASS"
    else
        print_warning "  ⚠ IAM access limited or denied (this may be expected)"
        IAM_STATUS="WARN"
    fi
    
    # Store results
    RESULTS["$PROFILE_NAME"]="$PROFILE_STATUS|$IDENTITY_STATUS|$REGION_STATUS|$S3_STATUS|$IAM_STATUS"
    
    if [ "$PROFILE_STATUS" = "PASS" ]; then
        ((PASS_COUNT++))
    fi
    
    echo ""
done

# Summary Report
echo ""
echo -e "${CYAN}============================================================${NC}"
echo -e "${CYAN}Validation Summary Report${NC}"
echo -e "${CYAN}============================================================${NC}"
echo ""

printf "%-30s %-10s %-10s %-10s %-10s %-10s\n" "Profile" "Identity" "Region" "S3" "IAM" "Status"
printf "%-30s %-10s %-10s %-10s %-10s %-10s\n" "-------" "--------" "------" "---" "---" "------"

for PROFILE_NAME in "${PROFILES_TO_TEST[@]}"; do
    IFS='|' read -r STATUS IDENTITY REGION S3 IAM <<< "${RESULTS[$PROFILE_NAME]}"
    
    # Color code the status
    if [ "$STATUS" = "PASS" ]; then
        STATUS_COLOR="${GREEN}PASS${NC}"
    else
        STATUS_COLOR="${RED}FAIL${NC}"
    fi
    
    printf "%-30s %-10s %-10s %-10s %-10s " "$PROFILE_NAME" "$IDENTITY" "$REGION" "$S3" "$IAM"
    echo -e "$STATUS_COLOR"
done

# Overall status
echo ""
if [ $PASS_COUNT -eq $TOTAL_COUNT ]; then
    print_success "✓ All profiles validated successfully ($PASS_COUNT/$TOTAL_COUNT)"
    echo ""
    print_success "Your AWS CLI configuration is ready to use! 🎉"
else
    FAIL_COUNT=$((TOTAL_COUNT - PASS_COUNT))
    print_warning "⚠ Some profiles failed validation ($FAIL_COUNT/$TOTAL_COUNT failed)"
    echo ""
    print_info "Troubleshooting tips:"
    echo "  1. Check your credentials in: $CREDENTIALS_FILE"
    echo "  2. Verify account IDs in: $CONFIG_FILE"
    echo "  3. Ensure MFA token is correct (if enabled)"
    echo "  4. Check IAM role trust relationships"
    echo "  5. Review the README.md troubleshooting section"
fi

echo ""
print_info "For detailed usage instructions, see: infrastructure/aws-cli/README.md"
