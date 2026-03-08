#!/bin/bash
# SwasthyaAI AWS CLI Configuration Script (Bash)
# This script automates the setup of AWS CLI profiles for multi-account access

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Helper functions
print_success() { echo -e "${GREEN}$1${NC}"; }
print_info() { echo -e "${CYAN}$1${NC}"; }
print_warning() { echo -e "${YELLOW}$1${NC}"; }
print_error() { echo -e "${RED}$1${NC}"; }

# Parse command line arguments
SKIP_VALIDATION=false
USE_SSO=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --skip-validation)
            SKIP_VALIDATION=true
            shift
            ;;
        --use-sso)
            USE_SSO=true
            shift
            ;;
        *)
            echo "Unknown option: $1"
            echo "Usage: $0 [--skip-validation] [--use-sso]"
            exit 1
            ;;
    esac
done

# Banner
echo -e "${CYAN}"
cat << "EOF"
╔═══════════════════════════════════════════════════════════╗
║     SwasthyaAI AWS CLI Configuration Script               ║
║     Multi-Account Setup for Dev, Staging, Prod            ║
╚═══════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# Check if AWS CLI is installed
print_info "\n[1/7] Checking AWS CLI installation..."
if command -v aws &> /dev/null; then
    AWS_VERSION=$(aws --version 2>&1)
    print_success "✓ AWS CLI is installed: $AWS_VERSION"
    
    # Check version
    if [[ $AWS_VERSION =~ aws-cli/([0-9]+)\. ]]; then
        MAJOR_VERSION="${BASH_REMATCH[1]}"
        if [ "$MAJOR_VERSION" -lt 2 ]; then
            print_warning "⚠ AWS CLI v1 detected. We recommend upgrading to v2 for better features."
        fi
    fi
else
    print_error "✗ AWS CLI is not installed!"
    print_info "Please install AWS CLI v2 from: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html"
    exit 1
fi

# Create AWS config directory if it doesn't exist
AWS_CONFIG_DIR="$HOME/.aws"
if [ ! -d "$AWS_CONFIG_DIR" ]; then
    print_info "\n[2/7] Creating AWS configuration directory..."
    mkdir -p "$AWS_CONFIG_DIR"
    chmod 700 "$AWS_CONFIG_DIR"
    print_success "✓ Created directory: $AWS_CONFIG_DIR"
else
    print_success "\n[2/7] ✓ AWS configuration directory exists"
fi

# Backup existing configuration
CONFIG_FILE="$AWS_CONFIG_DIR/config"
CREDENTIALS_FILE="$AWS_CONFIG_DIR/credentials"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

print_info "\n[3/7] Backing up existing configuration..."
if [ -f "$CONFIG_FILE" ]; then
    cp "$CONFIG_FILE" "$CONFIG_FILE.backup.$TIMESTAMP"
    print_success "✓ Backed up config to: config.backup.$TIMESTAMP"
fi

if [ -f "$CREDENTIALS_FILE" ]; then
    cp "$CREDENTIALS_FILE" "$CREDENTIALS_FILE.backup.$TIMESTAMP"
    print_success "✓ Backed up credentials to: credentials.backup.$TIMESTAMP"
fi

if [ ! -f "$CONFIG_FILE" ] && [ ! -f "$CREDENTIALS_FILE" ]; then
    print_success "✓ No existing configuration to backup"
fi

# Collect account information
print_info "\n[4/7] Collecting AWS account information..."
echo ""

if [ "$USE_SSO" = true ]; then
    print_info "SSO Configuration Mode"
    echo ""
    read -p "Enter your AWS SSO start URL: " SSO_START_URL
    read -p "Enter SSO region (default: ap-south-1): " SSO_REGION
    SSO_REGION=${SSO_REGION:-ap-south-1}
    
    print_info "\nConfiguring SSO profiles..."
    print_info "You will be prompted to authenticate via browser for each account."
    
    # Configure SSO for each environment
    ENVIRONMENTS=("dev" "staging" "prod" "security")
    for ENV in "${ENVIRONMENTS[@]}"; do
        print_info "\nConfiguring swasthyaai-$ENV profile..."
        aws configure sso --profile "swasthyaai-$ENV"
    done
    
    print_success "\n✓ SSO profiles configured"
else
    print_info "IAM User Configuration Mode"
    echo ""
    
    # Management account credentials
    echo -e "${YELLOW}Management Account Credentials:${NC}"
    read -p "Enter AWS Access Key ID for management account: " MANAGEMENT_ACCESS_KEY
    read -sp "Enter AWS Secret Access Key for management account: " MANAGEMENT_SECRET_KEY
    echo ""
    
    # Account IDs
    echo -e "\n${YELLOW}AWS Account IDs:${NC}"
    read -p "Enter Management Account ID: " MANAGEMENT_ACCOUNT_ID
    read -p "Enter Dev Account ID: " DEV_ACCOUNT_ID
    read -p "Enter Staging Account ID: " STAGING_ACCOUNT_ID
    read -p "Enter Prod Account ID: " PROD_ACCOUNT_ID
    read -p "Enter Security Account ID: " SECURITY_ACCOUNT_ID
    
    # MFA configuration
    echo -e "\n${YELLOW}MFA Configuration:${NC}"
    read -p "Do you want to enable MFA? (y/n): " USE_MFA
    MFA_SERIAL=""
    if [ "$USE_MFA" = "y" ]; then
        read -p "Enter your IAM username: " IAM_USERNAME
        MFA_SERIAL="arn:aws:iam::${MANAGEMENT_ACCOUNT_ID}:mfa/${IAM_USERNAME}"
        print_info "MFA Serial: $MFA_SERIAL"
    fi
    
    # Default region
    read -p "\nEnter default region (default: ap-south-1): " DEFAULT_REGION
    DEFAULT_REGION=${DEFAULT_REGION:-ap-south-1}
    
    # Create credentials file
    print_info "\n[5/7] Creating credentials file..."
    cat > "$CREDENTIALS_FILE" << EOF
[swasthyaai-management]
aws_access_key_id = $MANAGEMENT_ACCESS_KEY
aws_secret_access_key = $MANAGEMENT_SECRET_KEY
EOF
    
    chmod 600 "$CREDENTIALS_FILE"
    print_success "✓ Credentials file created"
    
    # Create config file
    print_info "\n[6/7] Creating config file..."
    cat > "$CONFIG_FILE" << EOF
[profile swasthyaai-management]
region = $DEFAULT_REGION
output = json

[profile swasthyaai-dev]
region = $DEFAULT_REGION
output = json
role_arn = arn:aws:iam::${DEV_ACCOUNT_ID}:role/OrganizationAccountAccessRole
source_profile = swasthyaai-management
EOF
    
    if [ "$USE_MFA" = "y" ]; then
        echo "mfa_serial = $MFA_SERIAL" >> "$CONFIG_FILE"
    fi
    
    cat >> "$CONFIG_FILE" << EOF

[profile swasthyaai-staging]
region = $DEFAULT_REGION
output = json
role_arn = arn:aws:iam::${STAGING_ACCOUNT_ID}:role/OrganizationAccountAccessRole
source_profile = swasthyaai-management
EOF
    
    if [ "$USE_MFA" = "y" ]; then
        echo "mfa_serial = $MFA_SERIAL" >> "$CONFIG_FILE"
    fi
    
    cat >> "$CONFIG_FILE" << EOF

[profile swasthyaai-prod]
region = $DEFAULT_REGION
output = json
role_arn = arn:aws:iam::${PROD_ACCOUNT_ID}:role/OrganizationAccountAccessRole
source_profile = swasthyaai-management
EOF
    
    if [ "$USE_MFA" = "y" ]; then
        echo "mfa_serial = $MFA_SERIAL" >> "$CONFIG_FILE"
    fi
    
    cat >> "$CONFIG_FILE" << EOF

[profile swasthyaai-security]
region = $DEFAULT_REGION
output = json
role_arn = arn:aws:iam::${SECURITY_ACCOUNT_ID}:role/OrganizationAccountAccessRole
source_profile = swasthyaai-management
EOF
    
    if [ "$USE_MFA" = "y" ]; then
        echo "mfa_serial = $MFA_SERIAL" >> "$CONFIG_FILE"
    fi
    
    chmod 600 "$CONFIG_FILE"
    print_success "✓ Config file created"
fi

# Validate configuration
if [ "$SKIP_VALIDATION" = false ]; then
    print_info "\n[7/7] Validating configuration..."
    echo ""
    
    PROFILES=("swasthyaai-management" "swasthyaai-dev" "swasthyaai-staging" "swasthyaai-prod" "swasthyaai-security")
    declare -A VALIDATION_RESULTS
    SUCCESS_COUNT=0
    TOTAL_COUNT=${#PROFILES[@]}
    
    for PROFILE in "${PROFILES[@]}"; do
        print_info "Testing profile: $PROFILE"
        if RESULT=$(aws sts get-caller-identity --profile "$PROFILE" 2>&1); then
            ACCOUNT=$(echo "$RESULT" | grep -o '"Account": "[^"]*"' | cut -d'"' -f4)
            print_success "  ✓ Success - Account: $ACCOUNT"
            VALIDATION_RESULTS[$PROFILE]="PASS"
            ((SUCCESS_COUNT++))
        else
            print_error "  ✗ Failed - $RESULT"
            VALIDATION_RESULTS[$PROFILE]="FAIL"
        fi
    done
    
    # Summary
    echo ""
    echo -e "${CYAN}============================================================${NC}"
    echo -e "${CYAN}Validation Summary:${NC}"
    echo -e "${CYAN}============================================================${NC}"
    
    for PROFILE in "${PROFILES[@]}"; do
        if [ "${VALIDATION_RESULTS[$PROFILE]}" = "PASS" ]; then
            print_success "✓ PASS - $PROFILE"
        else
            print_error "✗ FAIL - $PROFILE"
        fi
    done
    
    echo ""
    if [ $SUCCESS_COUNT -eq $TOTAL_COUNT ]; then
        print_success "Results: $SUCCESS_COUNT/$TOTAL_COUNT profiles validated successfully"
    else
        print_warning "Results: $SUCCESS_COUNT/$TOTAL_COUNT profiles validated successfully"
    fi
else
    print_info "\n[7/7] Skipping validation (--skip-validation flag used)"
fi

# Final instructions
echo ""
echo -e "${GREEN}============================================================${NC}"
echo -e "${GREEN}Configuration Complete!${NC}"
echo -e "${GREEN}============================================================${NC}"

cat << EOF

Next Steps:
1. Test your configuration:
   aws sts get-caller-identity --profile swasthyaai-dev

2. Use profiles in commands:
   aws s3 ls --profile swasthyaai-dev

3. Set default profile (optional):
   export AWS_PROFILE=swasthyaai-dev

4. Use helper scripts:
   source ./switch-profile.sh dev

5. Review the README.md for detailed usage instructions

Configuration files location:
- Config: $CONFIG_FILE
- Credentials: $CREDENTIALS_FILE

Backup files (if any):
- Config backup: $CONFIG_FILE.backup.$TIMESTAMP
- Credentials backup: $CREDENTIALS_FILE.backup.$TIMESTAMP

EOF

print_success "Setup completed successfully! 🎉"
