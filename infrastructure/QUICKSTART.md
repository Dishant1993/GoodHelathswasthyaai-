# SwasthyaAI Infrastructure - Quick Start Guide

This guide will help you quickly set up the AWS Organizations infrastructure for SwasthyaAI.

## Prerequisites Checklist

- [ ] AWS account with Organizations enabled
- [ ] Terraform installed (>= 1.0)
- [ ] AWS CLI installed and configured
- [ ] 4 unique email addresses for AWS accounts

## Quick Setup (5 Minutes)

### Step 1: Prepare Email Addresses

You need 4 unique email addresses. If you use Gmail, you can use the `+` trick:
- `yourname+swasthyaai-dev@gmail.com`
- `yourname+swasthyaai-staging@gmail.com`
- `yourname+swasthyaai-prod@gmail.com`
- `yourname+swasthyaai-security@gmail.com`

### Step 2: Configure Variables

Edit the environment file for your target environment:

```bash
# For development
nano environments/dev.tfvars
```

Update the email addresses:
```hcl
dev_account_email      = "yourname+swasthyaai-dev@gmail.com"
staging_account_email  = "yourname+swasthyaai-staging@gmail.com"
prod_account_email     = "yourname+swasthyaai-prod@gmail.com"
security_account_email = "yourname+swasthyaai-security@gmail.com"
```

### Step 3: Deploy Using Script

#### On Linux/macOS:

```bash
# Make script executable
chmod +x deploy.sh

# Setup backend and initialize
./deploy.sh setup

# Plan deployment
./deploy.sh plan dev

# Apply deployment
./deploy.sh apply dev
```

#### On Windows (PowerShell):

```powershell
# Setup backend and initialize
.\deploy.ps1 setup

# Plan deployment
.\deploy.ps1 plan -Environment dev

# Apply deployment
.\deploy.ps1 apply -Environment dev
```

### Step 4: Verify Deployment

After deployment completes, verify the outputs:

```bash
terraform output
```

You should see:
- Organization ID
- Account IDs for dev, staging, prod, and security
- Organizational Unit IDs

## Manual Deployment (Alternative)

If you prefer manual deployment:

```bash
# 1. Initialize Terraform
terraform init

# 2. Plan deployment
terraform plan -var-file="environments/dev.tfvars"

# 3. Apply deployment
terraform apply -var-file="environments/dev.tfvars"
```

## What Gets Created?

### AWS Organization Structure
```
Root
├── Workloads OU
│   ├── swasthyaai-dev
│   ├── swasthyaai-staging
│   └── swasthyaai-prod
└── Security OU
    └── swasthyaai-security
```

### Service Control Policies (SCPs)
1. **Deny Leave Organization** - Prevents accounts from leaving
2. **Enforce Encryption** - Requires encryption for S3, EBS, RDS
3. **Enforce India Regions** - Restricts to ap-south-1, ap-south-2
4. **Require MFA** - Requires MFA for sensitive operations
5. **Deny Root User** - Restricts root user access

## Post-Deployment Steps

### 1. Access the New Accounts

Each account will receive an email invitation. Accept the invitations to activate the accounts.

### 2. Configure AWS CLI Profiles

Add profiles to `~/.aws/config`:

```ini
[profile swasthyaai-dev]
role_arn = arn:aws:iam::<DEV_ACCOUNT_ID>:role/OrganizationAccountAccessRole
source_profile = default
region = ap-south-1

[profile swasthyaai-staging]
role_arn = arn:aws:iam::<STAGING_ACCOUNT_ID>:role/OrganizationAccountAccessRole
source_profile = default
region = ap-south-1

[profile swasthyaai-prod]
role_arn = arn:aws:iam::<PROD_ACCOUNT_ID>:role/OrganizationAccountAccessRole
source_profile = default
region = ap-south-1
```

Replace `<DEV_ACCOUNT_ID>`, `<STAGING_ACCOUNT_ID>`, and `<PROD_ACCOUNT_ID>` with actual account IDs from the output.

### 3. Test Account Access

```bash
# Test dev account access
aws sts get-caller-identity --profile swasthyaai-dev

# Test staging account access
aws sts get-caller-identity --profile swasthyaai-staging

# Test prod account access
aws sts get-caller-identity --profile swasthyaai-prod
```

### 4. Enable MFA for Root Users

For each account:
1. Sign in as root user
2. Go to IAM → Dashboard
3. Enable MFA for root account
4. Use Google Authenticator or similar app

### 5. Create IAM Users

In each account, create IAM users for your team:

```bash
# Switch to dev account
export AWS_PROFILE=swasthyaai-dev

# Create IAM user
aws iam create-user --user-name john.doe

# Attach administrator policy (adjust as needed)
aws iam attach-user-policy \
  --user-name john.doe \
  --policy-arn arn:aws:iam::aws:policy/AdministratorAccess

# Create access key
aws iam create-access-key --user-name john.doe
```

## Common Issues and Solutions

### Issue: "Email already in use"
**Solution**: Use a different email or email alias (e.g., `name+alias@gmail.com`)

### Issue: "Organization already exists"
**Solution**: Import existing organization:
```bash
terraform import aws_organizations_organization.swasthyaai <org-id>
```

### Issue: "Insufficient permissions"
**Solution**: Ensure your AWS user has these permissions:
- `organizations:*`
- `iam:CreateRole`
- `iam:AttachRolePolicy`

### Issue: Backend bucket doesn't exist
**Solution**: Run the setup script first:
```bash
./deploy.sh setup
```

## Cost Estimate

AWS Organizations is free. The only costs are:
- S3 bucket for Terraform state: ~$0.01/month
- DynamoDB table for state locking: ~$0.01/month

**Total estimated cost: ~$0.02/month**

## Next Steps

After setting up AWS Organizations:

1. ✅ Configure AWS CLI profiles for each account
2. ⬜ Deploy VPC infrastructure (Task 1.1.3)
3. ⬜ Set up IAM roles and policies (Task 1.2.x)
4. ⬜ Configure CloudTrail and monitoring (Task 1.3.x)
5. ⬜ Deploy data layer (DynamoDB, RDS, S3) (Task 2.x)

## Getting Help

- **Documentation**: See [README.md](README.md) for detailed information
- **Terraform Docs**: https://registry.terraform.io/providers/hashicorp/aws/latest/docs
- **AWS Organizations**: https://docs.aws.amazon.com/organizations/

## Cleanup

To destroy the infrastructure:

```bash
# Linux/macOS
./deploy.sh destroy dev

# Windows
.\deploy.ps1 destroy -Environment dev
```

**Warning**: AWS accounts cannot be deleted immediately. They will be suspended and deleted after 90 days.

---

**Need help?** Contact the SwasthyaAI infrastructure team.
