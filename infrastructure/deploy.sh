#!/bin/bash

# SwasthyaAI Infrastructure Deployment Script
# This script helps deploy the AWS infrastructure using Terraform

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check prerequisites
check_prerequisites() {
    print_info "Checking prerequisites..."
    
    # Check if Terraform is installed
    if ! command -v terraform &> /dev/null; then
        print_error "Terraform is not installed. Please install Terraform first."
        exit 1
    fi
    
    # Check if AWS CLI is installed
    if ! command -v aws &> /dev/null; then
        print_error "AWS CLI is not installed. Please install AWS CLI first."
        exit 1
    fi
    
    # Check if AWS credentials are configured
    if ! aws sts get-caller-identity &> /dev/null; then
        print_error "AWS credentials are not configured. Please run 'aws configure' first."
        exit 1
    fi
    
    print_info "All prerequisites met!"
}

# Function to setup backend
setup_backend() {
    print_info "Setting up Terraform backend..."
    
    BUCKET_NAME="swasthyaai-terraform-state"
    TABLE_NAME="terraform-state-lock"
    REGION="ap-south-1"
    
    # Check if S3 bucket exists
    if aws s3 ls "s3://${BUCKET_NAME}" 2>&1 | grep -q 'NoSuchBucket'; then
        print_info "Creating S3 bucket for Terraform state..."
        aws s3api create-bucket \
            --bucket ${BUCKET_NAME} \
            --region ${REGION} \
            --create-bucket-configuration LocationConstraint=${REGION}
        
        # Enable versioning
        aws s3api put-bucket-versioning \
            --bucket ${BUCKET_NAME} \
            --versioning-configuration Status=Enabled
        
        # Enable encryption
        aws s3api put-bucket-encryption \
            --bucket ${BUCKET_NAME} \
            --server-side-encryption-configuration '{
                "Rules": [{
                    "ApplyServerSideEncryptionByDefault": {
                        "SSEAlgorithm": "AES256"
                    }
                }]
            }'
        
        print_info "S3 bucket created successfully!"
    else
        print_info "S3 bucket already exists."
    fi
    
    # Check if DynamoDB table exists
    if ! aws dynamodb describe-table --table-name ${TABLE_NAME} --region ${REGION} &> /dev/null; then
        print_info "Creating DynamoDB table for state locking..."
        aws dynamodb create-table \
            --table-name ${TABLE_NAME} \
            --attribute-definitions AttributeName=LockID,AttributeType=S \
            --key-schema AttributeName=LockID,KeyType=HASH \
            --billing-mode PAY_PER_REQUEST \
            --region ${REGION}
        
        print_info "DynamoDB table created successfully!"
    else
        print_info "DynamoDB table already exists."
    fi
}

# Function to initialize Terraform
init_terraform() {
    print_info "Initializing Terraform..."
    terraform init
    print_info "Terraform initialized successfully!"
}

# Function to validate configuration
validate_config() {
    print_info "Validating Terraform configuration..."
    terraform validate
    print_info "Configuration is valid!"
}

# Function to plan deployment
plan_deployment() {
    local env=$1
    print_info "Planning deployment for ${env} environment..."
    terraform plan -var-file="environments/${env}.tfvars" -out="${env}.tfplan"
    print_info "Plan saved to ${env}.tfplan"
}

# Function to apply deployment
apply_deployment() {
    local env=$1
    print_warning "This will create AWS resources. Are you sure? (yes/no)"
    read -r confirmation
    
    if [ "$confirmation" = "yes" ]; then
        print_info "Applying deployment for ${env} environment..."
        terraform apply "${env}.tfplan"
        print_info "Deployment completed successfully!"
        
        # Show outputs
        print_info "Deployment outputs:"
        terraform output
    else
        print_info "Deployment cancelled."
        exit 0
    fi
}

# Function to destroy infrastructure
destroy_infrastructure() {
    local env=$1
    print_warning "WARNING: This will destroy all infrastructure in ${env} environment!"
    print_warning "This action cannot be undone. Type 'destroy' to confirm:"
    read -r confirmation
    
    if [ "$confirmation" = "destroy" ]; then
        print_info "Destroying infrastructure for ${env} environment..."
        terraform destroy -var-file="environments/${env}.tfvars"
        print_info "Infrastructure destroyed."
    else
        print_info "Destruction cancelled."
        exit 0
    fi
}

# Function to show outputs
show_outputs() {
    print_info "Terraform outputs:"
    terraform output
}

# Main script
main() {
    echo "=========================================="
    echo "SwasthyaAI Infrastructure Deployment"
    echo "=========================================="
    echo ""
    
    # Check if environment is provided
    if [ $# -eq 0 ]; then
        print_error "Usage: $0 <command> [environment]"
        echo ""
        echo "Commands:"
        echo "  setup       - Setup backend and initialize Terraform"
        echo "  plan        - Plan deployment (requires environment: dev/staging/prod)"
        echo "  apply       - Apply deployment (requires environment: dev/staging/prod)"
        echo "  destroy     - Destroy infrastructure (requires environment: dev/staging/prod)"
        echo "  output      - Show outputs"
        echo ""
        echo "Examples:"
        echo "  $0 setup"
        echo "  $0 plan dev"
        echo "  $0 apply dev"
        echo "  $0 destroy dev"
        echo "  $0 output"
        exit 1
    fi
    
    COMMAND=$1
    ENVIRONMENT=$2
    
    case $COMMAND in
        setup)
            check_prerequisites
            setup_backend
            init_terraform
            validate_config
            print_info "Setup completed! You can now run: $0 plan <environment>"
            ;;
        plan)
            if [ -z "$ENVIRONMENT" ]; then
                print_error "Environment is required for plan command (dev/staging/prod)"
                exit 1
            fi
            check_prerequisites
            plan_deployment $ENVIRONMENT
            print_info "Review the plan and run: $0 apply $ENVIRONMENT"
            ;;
        apply)
            if [ -z "$ENVIRONMENT" ]; then
                print_error "Environment is required for apply command (dev/staging/prod)"
                exit 1
            fi
            check_prerequisites
            apply_deployment $ENVIRONMENT
            ;;
        destroy)
            if [ -z "$ENVIRONMENT" ]; then
                print_error "Environment is required for destroy command (dev/staging/prod)"
                exit 1
            fi
            check_prerequisites
            destroy_infrastructure $ENVIRONMENT
            ;;
        output)
            show_outputs
            ;;
        *)
            print_error "Unknown command: $COMMAND"
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
