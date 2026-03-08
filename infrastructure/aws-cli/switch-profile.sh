#!/bin/bash
# SwasthyaAI AWS Profile Switcher (Bash)
# Quick helper script to switch between AWS profiles
# Usage: source ./switch-profile.sh <environment>

# Color codes
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
GRAY='\033[0;37m'
NC='\033[0m' # No Color

# Check if environment argument is provided
if [ $# -eq 0 ]; then
    echo -e "${YELLOW}Usage: source ./switch-profile.sh <environment>${NC}"
    echo -e "${CYAN}Available environments:${NC}"
    echo "  management - Management account"
    echo "  dev        - Development environment"
    echo "  staging    - Staging environment"
    echo "  prod       - Production environment"
    echo "  security   - Security account"
    echo "  clear      - Clear AWS_PROFILE variable"
    return 1 2>/dev/null || exit 1
fi

ENVIRONMENT=$1

# Profile mapping
declare -A PROFILES
PROFILES[management]="swasthyaai-management"
PROFILES[dev]="swasthyaai-dev"
PROFILES[staging]="swasthyaai-staging"
PROFILES[prod]="swasthyaai-prod"
PROFILES[security]="swasthyaai-security"

if [ "$ENVIRONMENT" = "clear" ]; then
    unset AWS_PROFILE
    echo -e "${GREEN}✓ AWS_PROFILE environment variable cleared${NC}"
    echo -e "${CYAN}AWS CLI will now use default profile or --profile flag${NC}"
elif [ -n "${PROFILES[$ENVIRONMENT]}" ]; then
    PROFILE_NAME="${PROFILES[$ENVIRONMENT]}"
    export AWS_PROFILE="$PROFILE_NAME"
    
    echo -e "${GREEN}✓ Switched to profile: $PROFILE_NAME${NC}"
    echo ""
    echo -e "${CYAN}Current AWS Identity:${NC}"
    
    if IDENTITY=$(aws sts get-caller-identity 2>&1); then
        ACCOUNT=$(echo "$IDENTITY" | grep -o '"Account": "[^"]*"' | cut -d'"' -f4)
        ARN=$(echo "$IDENTITY" | grep -o '"Arn": "[^"]*"' | cut -d'"' -f4)
        echo -e "${GRAY}  Account: $ACCOUNT${NC}"
        echo -e "${GRAY}  User: $ARN${NC}"
        echo ""
        echo -e "${YELLOW}Environment: $ENVIRONMENT${NC}"
        echo -e "${YELLOW}Profile: $PROFILE_NAME${NC}"
    else
        echo -e "${YELLOW}  Could not verify identity (you may need to authenticate)${NC}"
    fi
else
    echo -e "${RED}✗ Invalid environment: $ENVIRONMENT${NC}"
    echo -e "${CYAN}Available environments: management, dev, staging, prod, security, clear${NC}"
    return 1 2>/dev/null || exit 1
fi

echo ""
echo -e "${CYAN}Usage examples:${NC}"
echo -e "${GRAY}  aws s3 ls${NC}"
echo -e "${GRAY}  aws dynamodb list-tables${NC}"
echo -e "${GRAY}  terraform plan${NC}"
