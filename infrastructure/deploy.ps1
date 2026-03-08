# SwasthyaAI Infrastructure Deployment Script (PowerShell)
# This script helps deploy the AWS infrastructure using Terraform

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet('setup', 'plan', 'apply', 'destroy', 'output')]
    [string]$Command,
    
    [Parameter(Mandatory=$false)]
    [ValidateSet('dev', 'staging', 'prod')]
    [string]$Environment
)

# Function to print colored output
function Write-Info {
    param([string]$Message)
    Write-Host "[INFO] $Message" -ForegroundColor Green
}

function Write-Warning-Custom {
    param([string]$Message)
    Write-Host "[WARNING] $Message" -ForegroundColor Yellow
}

function Write-Error-Custom {
    param([string]$Message)
    Write-Host "[ERROR] $Message" -ForegroundColor Red
}

# Function to check prerequisites
function Test-Prerequisites {
    Write-Info "Checking prerequisites..."
    
    # Check if Terraform is installed
    if (-not (Get-Command terraform -ErrorAction SilentlyContinue)) {
        Write-Error-Custom "Terraform is not installed. Please install Terraform first."
        exit 1
    }
    
    # Check if AWS CLI is installed
    if (-not (Get-Command aws -ErrorAction SilentlyContinue)) {
        Write-Error-Custom "AWS CLI is not installed. Please install AWS CLI first."
        exit 1
    }
    
    # Check if AWS credentials are configured
    try {
        aws sts get-caller-identity | Out-Null
    }
    catch {
        Write-Error-Custom "AWS credentials are not configured. Please run 'aws configure' first."
        exit 1
    }
    
    Write-Info "All prerequisites met!"
}

# Function to setup backend
function Initialize-Backend {
    Write-Info "Setting up Terraform backend..."
    
    $BucketName = "swasthyaai-terraform-state"
    $TableName = "terraform-state-lock"
    $Region = "ap-south-1"
    
    # Check if S3 bucket exists
    try {
        aws s3 ls "s3://$BucketName" 2>&1 | Out-Null
        Write-Info "S3 bucket already exists."
    }
    catch {
        Write-Info "Creating S3 bucket for Terraform state..."
        aws s3api create-bucket `
            --bucket $BucketName `
            --region $Region `
            --create-bucket-configuration LocationConstraint=$Region
        
        # Enable versioning
        aws s3api put-bucket-versioning `
            --bucket $BucketName `
            --versioning-configuration Status=Enabled
        
        # Enable encryption
        $encryptionConfig = @{
            Rules = @(
                @{
                    ApplyServerSideEncryptionByDefault = @{
                        SSEAlgorithm = "AES256"
                    }
                }
            )
        } | ConvertTo-Json -Depth 10
        
        aws s3api put-bucket-encryption `
            --bucket $BucketName `
            --server-side-encryption-configuration $encryptionConfig
        
        Write-Info "S3 bucket created successfully!"
    }
    
    # Check if DynamoDB table exists
    try {
        aws dynamodb describe-table --table-name $TableName --region $Region | Out-Null
        Write-Info "DynamoDB table already exists."
    }
    catch {
        Write-Info "Creating DynamoDB table for state locking..."
        aws dynamodb create-table `
            --table-name $TableName `
            --attribute-definitions AttributeName=LockID,AttributeType=S `
            --key-schema AttributeName=LockID,KeyType=HASH `
            --billing-mode PAY_PER_REQUEST `
            --region $Region
        
        Write-Info "DynamoDB table created successfully!"
    }
}

# Function to initialize Terraform
function Initialize-Terraform {
    Write-Info "Initializing Terraform..."
    terraform init
    Write-Info "Terraform initialized successfully!"
}

# Function to validate configuration
function Test-Configuration {
    Write-Info "Validating Terraform configuration..."
    terraform validate
    Write-Info "Configuration is valid!"
}

# Function to plan deployment
function New-DeploymentPlan {
    param([string]$Env)
    Write-Info "Planning deployment for $Env environment..."
    terraform plan -var-file="environments/$Env.tfvars" -out="$Env.tfplan"
    Write-Info "Plan saved to $Env.tfplan"
}

# Function to apply deployment
function Start-Deployment {
    param([string]$Env)
    Write-Warning-Custom "This will create AWS resources. Are you sure? (yes/no)"
    $confirmation = Read-Host
    
    if ($confirmation -eq "yes") {
        Write-Info "Applying deployment for $Env environment..."
        terraform apply "$Env.tfplan"
        Write-Info "Deployment completed successfully!"
        
        # Show outputs
        Write-Info "Deployment outputs:"
        terraform output
    }
    else {
        Write-Info "Deployment cancelled."
        exit 0
    }
}

# Function to destroy infrastructure
function Remove-Infrastructure {
    param([string]$Env)
    Write-Warning-Custom "WARNING: This will destroy all infrastructure in $Env environment!"
    Write-Warning-Custom "This action cannot be undone. Type 'destroy' to confirm:"
    $confirmation = Read-Host
    
    if ($confirmation -eq "destroy") {
        Write-Info "Destroying infrastructure for $Env environment..."
        terraform destroy -var-file="environments/$Env.tfvars"
        Write-Info "Infrastructure destroyed."
    }
    else {
        Write-Info "Destruction cancelled."
        exit 0
    }
}

# Function to show outputs
function Show-Outputs {
    Write-Info "Terraform outputs:"
    terraform output
}

# Main script
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "SwasthyaAI Infrastructure Deployment" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

switch ($Command) {
    'setup' {
        Test-Prerequisites
        Initialize-Backend
        Initialize-Terraform
        Test-Configuration
        Write-Info "Setup completed! You can now run: .\deploy.ps1 plan -Environment <env>"
    }
    'plan' {
        if (-not $Environment) {
            Write-Error-Custom "Environment is required for plan command (dev/staging/prod)"
            exit 1
        }
        Test-Prerequisites
        New-DeploymentPlan -Env $Environment
        Write-Info "Review the plan and run: .\deploy.ps1 apply -Environment $Environment"
    }
    'apply' {
        if (-not $Environment) {
            Write-Error-Custom "Environment is required for apply command (dev/staging/prod)"
            exit 1
        }
        Test-Prerequisites
        Start-Deployment -Env $Environment
    }
    'destroy' {
        if (-not $Environment) {
            Write-Error-Custom "Environment is required for destroy command (dev/staging/prod)"
            exit 1
        }
        Test-Prerequisites
        Remove-Infrastructure -Env $Environment
    }
    'output' {
        Show-Outputs
    }
}
