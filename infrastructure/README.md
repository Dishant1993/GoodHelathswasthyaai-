# SwasthyaAI Infrastructure

This directory contains Terraform configurations for deploying SwasthyaAI's AWS infrastructure, including AWS Organizations setup with separate accounts for development, staging, and production environments.

## Architecture Overview

The infrastructure follows a multi-account AWS architecture with:

- **AWS Organization**: Central management of all accounts
- **Development Account**: For development and testing
- **Staging Account**: For pre-production validation
- **Production Account**: For live deployment
- **Security Account**: For centralized security and audit logging

## Prerequisites

1. **AWS Account**: You need an AWS account with Organizations enabled
2. **Terraform**: Install Terraform >= 1.0
   ```bash
   # macOS
   brew install terraform
   
   # Windows
   choco install terraform
   
   # Linux
   wget https://releases.hashicorp.com/terraform/1.6.0/terraform_1.6.0_linux_amd64.zip
   unzip terraform_1.6.0_linux_amd64.zip
   sudo mv terraform /usr/local/bin/
   ```

3. **AWS CLI**: Install and configure AWS CLI
   ```bash
   # Install
   pip install awscli
   
   # Configure
   aws configure
   ```

4. **Unique Email Addresses**: You need 4 unique email addresses for the AWS accounts:
   - Development account email
   - Staging account email
   - Production account email
   - Security account email

## Directory Structure

```
infrastructure/
├── main.tf                    # Main Terraform configuration
├── variables.tf               # Variable definitions
├── organizations.tf           # AWS Organizations setup
├── vpc.tf                     # VPC configuration
├── s3.tf                      # S3 buckets
├── dynamodb.tf               # DynamoDB tables
├── terraform.tfvars.example  # Example variables file
├── environments/             # Environment-specific configs
│   ├── dev.tfvars
│   ├── staging.tfvars
│   └── prod.tfvars
└── README.md                 # This file
```

## Setup Instructions

### Step 1: Configure Email Addresses

1. Copy the example variables file:
   ```bash
   cp terraform.tfvars.example terraform.tfvars
   ```

2. Edit `terraform.tfvars` and update the email addresses:
   ```hcl
   dev_account_email      = "your-dev-email@example.com"
   staging_account_email  = "your-staging-email@example.com"
   prod_account_email     = "your-prod-email@example.com"
   security_account_email = "your-security-email@example.com"
   ```

   **Important**: Each email must be unique and not already associated with an AWS account.

### Step 2: Initialize Terraform

```bash
cd infrastructure
terraform init
```

This will:
- Download required provider plugins
- Initialize the backend (S3 for state storage)

### Step 3: Create S3 Backend (First Time Only)

Before running Terraform, you need to create the S3 bucket and DynamoDB table for state management:

```bash
# Create S3 bucket for Terraform state
aws s3api create-bucket \
  --bucket swasthyaai-terraform-state \
  --region ap-south-1 \
  --create-bucket-configuration LocationConstraint=ap-south-1

# Enable versioning
aws s3api put-bucket-versioning \
  --bucket swasthyaai-terraform-state \
  --versioning-configuration Status=Enabled

# Enable encryption
aws s3api put-bucket-encryption \
  --bucket swasthyaai-terraform-state \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }'

# Create DynamoDB table for state locking
aws dynamodb create-table \
  --table-name terraform-state-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST \
  --region ap-south-1
```

### Step 4: Plan the Deployment

Review what Terraform will create:

```bash
# For development environment
terraform plan -var-file="environments/dev.tfvars"

# For staging environment
terraform plan -var-file="environments/staging.tfvars"

# For production environment
terraform plan -var-file="environments/prod.tfvars"
```

### Step 5: Deploy the Infrastructure

Deploy to the desired environment:

```bash
# Deploy to development
terraform apply -var-file="environments/dev.tfvars"

# Deploy to staging
terraform apply -var-file="environments/staging.tfvars"

# Deploy to production
terraform apply -var-file="environments/prod.tfvars"
```

Type `yes` when prompted to confirm the deployment.

## AWS Organizations Structure

The Terraform configuration creates the following organization structure:

```
Root
├── Workloads OU
│   ├── swasthyaai-dev (Development Account)
│   ├── swasthyaai-staging (Staging Account)
│   └── swasthyaai-prod (Production Account)
└── Security OU
    └── swasthyaai-security (Security Account)
```

## Service Control Policies (SCPs)

The following SCPs are automatically applied:

### 1. Deny Leave Organization
Prevents accounts from leaving the organization.

### 2. Enforce Encryption
Requires encryption for:
- S3 objects (AES256 or KMS)
- EBS volumes
- RDS databases

### 3. Enforce India Regions
Restricts operations to India regions (ap-south-1, ap-south-2) for data residency compliance.

### 4. Require MFA
Requires MFA for sensitive operations like:
- Stopping/terminating EC2 instances
- Deleting RDS databases
- Deleting S3 buckets
- Deleting DynamoDB tables

### 5. Deny Root User
Denies root user access except for account management tasks.

## Account Access

After account creation, you can access each account using:

1. **AWS Console**: Use the OrganizationAccountAccessRole
   ```bash
   aws sts assume-role \
     --role-arn arn:aws:iam::<ACCOUNT_ID>:role/OrganizationAccountAccessRole \
     --role-session-name my-session
   ```

2. **AWS CLI Profile**: Configure profiles for each account
   ```ini
   # ~/.aws/config
   [profile swasthyaai-dev]
   role_arn = arn:aws:iam::<DEV_ACCOUNT_ID>:role/OrganizationAccountAccessRole
   source_profile = default
   
   [profile swasthyaai-staging]
   role_arn = arn:aws:iam::<STAGING_ACCOUNT_ID>:role/OrganizationAccountAccessRole
   source_profile = default
   
   [profile swasthyaai-prod]
   role_arn = arn:aws:iam::<PROD_ACCOUNT_ID>:role/OrganizationAccountAccessRole
   source_profile = default
   ```

## Outputs

After deployment, Terraform will output:

- `organization_id`: AWS Organization ID
- `organization_arn`: AWS Organization ARN
- `dev_account_id`: Development account ID
- `staging_account_id`: Staging account ID
- `prod_account_id`: Production account ID
- `security_account_id`: Security account ID
- `workloads_ou_id`: Workloads OU ID
- `security_ou_id`: Security OU ID

View outputs:
```bash
terraform output
```

## Environment-Specific Configurations

### Development Environment
- VPC CIDR: 10.0.0.0/16
- RDS: db.t3.micro
- ElastiCache: cache.t3.micro
- Lambda concurrency: 50
- MFA: Optional

### Staging Environment
- VPC CIDR: 10.1.0.0/16
- RDS: db.t3.small
- ElastiCache: cache.t3.small
- Lambda concurrency: 100
- MFA: Required

### Production Environment
- VPC CIDR: 10.2.0.0/16
- RDS: db.r5.large (Multi-AZ)
- ElastiCache: cache.r5.large
- Lambda concurrency: 200
- MFA: Required

## Security Best Practices

1. **Enable MFA**: Always enable MFA for root and IAM users
2. **Use IAM Roles**: Use IAM roles instead of access keys
3. **Least Privilege**: Grant minimum necessary permissions
4. **Enable CloudTrail**: Enable CloudTrail in all accounts
5. **Regular Audits**: Regularly review IAM policies and access
6. **Rotate Credentials**: Rotate access keys and passwords regularly
7. **Monitor Costs**: Set up billing alerts and budgets

## Troubleshooting

### Issue: Email Already in Use
**Error**: "Email address is already associated with an AWS account"

**Solution**: Use a different email address or use email aliases (e.g., yourname+dev@gmail.com)

### Issue: Organization Already Exists
**Error**: "An organization already exists"

**Solution**: Import the existing organization:
```bash
terraform import aws_organizations_organization.swasthyaai <organization-id>
```

### Issue: Insufficient Permissions
**Error**: "User is not authorized to perform: organizations:CreateAccount"

**Solution**: Ensure your AWS user has the following permissions:
- organizations:*
- iam:CreateRole
- iam:AttachRolePolicy

### Issue: Account Limit Reached
**Error**: "Account limit exceeded"

**Solution**: Request a limit increase through AWS Support.

## Cleanup

To destroy the infrastructure:

```bash
# WARNING: This will delete all resources!
terraform destroy -var-file="environments/dev.tfvars"
```

**Note**: AWS accounts cannot be deleted immediately. They will be suspended and deleted after 90 days.

## Next Steps

After setting up AWS Organizations:

1. Configure AWS CLI profiles for each account
2. Set up IAM users and roles in each account
3. Deploy VPC and networking infrastructure
4. Set up CloudTrail and GuardDuty
5. Configure AWS Config for compliance monitoring
6. Deploy application infrastructure (Lambda, API Gateway, etc.)

## Support

For issues or questions:
- Review the [Terraform AWS Provider Documentation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
- Check the [AWS Organizations Documentation](https://docs.aws.amazon.com/organizations/)
- Contact the SwasthyaAI infrastructure team

## License

Copyright © 2024 SwasthyaAI. All rights reserved.
