# AWS CLI Configuration Guide for SwasthyaAI

This guide provides comprehensive instructions for configuring AWS CLI to work with the SwasthyaAI multi-account infrastructure.

## Overview

SwasthyaAI uses a multi-account AWS setup with the following accounts:
- **Management Account**: AWS Organizations root account
- **Dev Account**: Development environment
- **Staging Account**: Pre-production testing
- **Prod Account**: Production environment
- **Security Account**: Centralized security and audit logs

## Prerequisites

1. **AWS CLI Installation**
   - AWS CLI v2 (recommended)
   - Installation instructions: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html

2. **Access Requirements**
   - IAM user credentials for the management account OR
   - SSO access configured by your administrator

3. **Permissions**
   - Cross-account assume role permissions
   - Access to AWS Organizations (for management account)

## Quick Start

### Option 1: Automated Setup (Recommended)

Run the automated configuration script:

**Windows (PowerShell):**
```powershell
.\configure-aws-cli.ps1
```

**Linux/Mac:**
```bash
chmod +x configure-aws-cli.sh
./configure-aws-cli.sh
```

### Option 2: Manual Setup

Follow the [Manual Configuration Guide](#manual-configuration) below.

## Manual Configuration

### Step 1: Install AWS CLI

**Windows:**
```powershell
# Download and run the MSI installer
msiexec.exe /i https://awscli.amazonaws.com/AWSCLIV2.msi
```

**Linux:**
```bash
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
```

**macOS:**
```bash
curl "https://awscli.amazonaws.com/AWSCLIV2.pkg" -o "AWSCLIV2.pkg"
sudo installer -pkg AWSCLIV2.pkg -target /
```

Verify installation:
```bash
aws --version
```

### Step 2: Configure Named Profiles

AWS CLI uses named profiles to manage multiple accounts. We'll create profiles for each environment.

#### 2.1 Configure Management Account (Base Profile)

```bash
aws configure --profile swasthyaai-management
```

Enter the following when prompted:
- **AWS Access Key ID**: Your IAM user access key
- **AWS Secret Access Key**: Your IAM user secret key
- **Default region name**: `ap-south-1` (Mumbai)
- **Default output format**: `json`

#### 2.2 Configure Environment Profiles (Using Assume Role)

Edit `~/.aws/config` (Linux/Mac) or `%USERPROFILE%\.aws\config` (Windows) and add:

```ini
[profile swasthyaai-management]
region = ap-south-1
output = json

[profile swasthyaai-dev]
region = ap-south-1
output = json
role_arn = arn:aws:iam::DEV_ACCOUNT_ID:role/OrganizationAccountAccessRole
source_profile = swasthyaai-management
mfa_serial = arn:aws:iam::MANAGEMENT_ACCOUNT_ID:mfa/YOUR_USERNAME

[profile swasthyaai-staging]
region = ap-south-1
output = json
role_arn = arn:aws:iam::STAGING_ACCOUNT_ID:role/OrganizationAccountAccessRole
source_profile = swasthyaai-management
mfa_serial = arn:aws:iam::MANAGEMENT_ACCOUNT_ID:mfa/YOUR_USERNAME

[profile swasthyaai-prod]
region = ap-south-1
output = json
role_arn = arn:aws:iam::PROD_ACCOUNT_ID:role/OrganizationAccountAccessRole
source_profile = swasthyaai-management
mfa_serial = arn:aws:iam::MANAGEMENT_ACCOUNT_ID:mfa/YOUR_USERNAME

[profile swasthyaai-security]
region = ap-south-1
output = json
role_arn = arn:aws:iam::SECURITY_ACCOUNT_ID:role/OrganizationAccountAccessRole
source_profile = swasthyaai-management
mfa_serial = arn:aws:iam::MANAGEMENT_ACCOUNT_ID:mfa/YOUR_USERNAME
```

**Note**: Replace the following placeholders:
- `DEV_ACCOUNT_ID`: Your dev account ID
- `STAGING_ACCOUNT_ID`: Your staging account ID
- `PROD_ACCOUNT_ID`: Your prod account ID
- `SECURITY_ACCOUNT_ID`: Your security account ID
- `MANAGEMENT_ACCOUNT_ID`: Your management account ID
- `YOUR_USERNAME`: Your IAM username

#### 2.3 Store Credentials Securely

Edit `~/.aws/credentials` (Linux/Mac) or `%USERPROFILE%\.aws\credentials` (Windows):

```ini
[swasthyaai-management]
aws_access_key_id = YOUR_ACCESS_KEY_ID
aws_secret_access_key = YOUR_SECRET_ACCESS_KEY
```

**Security Best Practices:**
- Never commit credentials to version control
- Use IAM roles instead of long-term credentials when possible
- Enable MFA for all accounts
- Rotate access keys regularly (every 90 days)
- Use AWS SSO for production environments

### Step 3: Verify Configuration

Run the validation script:

```bash
# Windows
.\validate-aws-config.ps1

# Linux/Mac
./validate-aws-config.sh
```

Or manually test each profile:

```bash
# Test management account
aws sts get-caller-identity --profile swasthyaai-management

# Test dev account
aws sts get-caller-identity --profile swasthyaai-dev

# Test staging account
aws sts get-caller-identity --profile swasthyaai-staging

# Test prod account
aws sts get-caller-identity --profile swasthyaai-prod

# Test security account
aws sts get-caller-identity --profile swasthyaai-security
```

Expected output for each command:
```json
{
    "UserId": "AIDAI...",
    "Account": "123456789012",
    "Arn": "arn:aws:sts::123456789012:assumed-role/OrganizationAccountAccessRole/..."
}
```

## Using AWS Profiles

### Method 1: Using --profile Flag

```bash
# List S3 buckets in dev account
aws s3 ls --profile swasthyaai-dev

# List DynamoDB tables in staging
aws dynamodb list-tables --profile swasthyaai-staging

# Deploy to production
aws cloudformation deploy --profile swasthyaai-prod --template-file template.yaml
```

### Method 2: Using Environment Variables

**Windows (PowerShell):**
```powershell
$env:AWS_PROFILE = "swasthyaai-dev"
aws s3 ls
```

**Linux/Mac:**
```bash
export AWS_PROFILE=swasthyaai-dev
aws s3 ls
```

### Method 3: Using Helper Scripts

We provide convenience scripts for quick profile switching:

**Windows:**
```powershell
.\switch-profile.ps1 dev
aws s3 ls  # Now uses dev profile
```

**Linux/Mac:**
```bash
source ./switch-profile.sh dev
aws s3 ls  # Now uses dev profile
```

## MFA Authentication

When MFA is enabled, you'll be prompted for your MFA token:

```bash
aws sts get-caller-identity --profile swasthyaai-dev
# Enter MFA code: 123456
```

The session will be cached for 12 hours (default). To force re-authentication:

```bash
aws sts get-session-token --profile swasthyaai-management --serial-number arn:aws:iam::ACCOUNT_ID:mfa/USERNAME --token-code 123456
```

## AWS SSO Configuration (Alternative)

For organizations using AWS SSO:

### Step 1: Configure SSO

```bash
aws configure sso
```

Follow the prompts:
- **SSO start URL**: Your organization's SSO URL
- **SSO region**: `ap-south-1`
- **SSO account**: Select your account
- **SSO role**: Select your role
- **CLI default region**: `ap-south-1`
- **CLI output format**: `json`
- **CLI profile name**: `swasthyaai-dev` (or appropriate name)

### Step 2: Login to SSO

```bash
aws sso login --profile swasthyaai-dev
```

This will open a browser for authentication.

### Step 3: Use SSO Profiles

```bash
aws s3 ls --profile swasthyaai-dev
```

## Troubleshooting

### Issue: "Unable to locate credentials"

**Solution:**
1. Verify credentials file exists: `~/.aws/credentials`
2. Check profile name matches in both config and credentials files
3. Ensure credentials are not expired

### Issue: "An error occurred (AccessDenied) when calling the AssumeRole operation"

**Solution:**
1. Verify the role ARN is correct
2. Check that the trust relationship allows your management account
3. Ensure your IAM user has `sts:AssumeRole` permission
4. Verify MFA token is correct (if required)

### Issue: "The security token included in the request is expired"

**Solution:**
1. Re-authenticate with MFA
2. Run: `aws sts get-session-token --profile swasthyaai-management --serial-number YOUR_MFA_ARN --token-code YOUR_MFA_CODE`

### Issue: "Could not connect to the endpoint URL"

**Solution:**
1. Check your internet connection
2. Verify the region is correct in your profile
3. Check if you're behind a proxy (configure AWS_PROXY if needed)

### Issue: MFA token not being accepted

**Solution:**
1. Ensure your device time is synchronized (MFA tokens are time-based)
2. Verify the MFA serial number is correct
3. Try generating a new token

## Security Best Practices

1. **Enable MFA**: Always enable MFA for production accounts
2. **Rotate Keys**: Rotate access keys every 90 days
3. **Least Privilege**: Use IAM roles with minimum required permissions
4. **Audit Access**: Regularly review CloudTrail logs
5. **Secure Storage**: Never commit credentials to version control
6. **Use IAM Roles**: Prefer IAM roles over long-term credentials
7. **Session Duration**: Use short session durations for assumed roles
8. **Separate Accounts**: Keep dev, staging, and prod strictly separated

## Environment-Specific Configuration

### Development Environment
- Profile: `swasthyaai-dev`
- Region: `ap-south-1`
- Use case: Daily development, testing, experimentation
- Data: Synthetic data only

### Staging Environment
- Profile: `swasthyaai-staging`
- Region: `ap-south-1`
- Use case: Pre-production testing, integration tests
- Data: Synthetic data, production-like configuration

### Production Environment
- Profile: `swasthyaai-prod`
- Region: `ap-south-1`
- Use case: Live system, real patient data (future)
- Data: Real PHI (requires additional compliance measures)
- **Extra caution required**: All changes must be reviewed and approved

### Security Account
- Profile: `swasthyaai-security`
- Region: `ap-south-1`
- Use case: Centralized audit logs, security monitoring
- Access: Limited to security team

## Integration with Infrastructure as Code

### Terraform

```bash
# Deploy to dev
export AWS_PROFILE=swasthyaai-dev
terraform init
terraform plan -var-file=environments/dev.tfvars
terraform apply -var-file=environments/dev.tfvars

# Deploy to staging
export AWS_PROFILE=swasthyaai-staging
terraform plan -var-file=environments/staging.tfvars
terraform apply -var-file=environments/staging.tfvars
```

### AWS CDK

```bash
# Deploy to dev
export AWS_PROFILE=swasthyaai-dev
cdk deploy --all --context env=dev

# Deploy to prod
export AWS_PROFILE=swasthyaai-prod
cdk deploy --all --context env=prod --require-approval always
```

## Additional Resources

- [AWS CLI Documentation](https://docs.aws.amazon.com/cli/latest/userguide/)
- [AWS CLI Configuration Guide](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html)
- [AWS Organizations Best Practices](https://docs.aws.amazon.com/organizations/latest/userguide/orgs_best-practices.html)
- [IAM Best Practices](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)

## Support

For issues or questions:
1. Check the troubleshooting section above
2. Review AWS CLI documentation
3. Contact the SwasthyaAI infrastructure team
4. Create an issue in the project repository

---

**Last Updated**: January 2024
**Maintained By**: SwasthyaAI Infrastructure Team
