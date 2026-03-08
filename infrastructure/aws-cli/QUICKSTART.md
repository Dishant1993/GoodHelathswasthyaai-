# AWS CLI Quick Start Guide

Get up and running with AWS CLI for SwasthyaAI in 5 minutes.

## Prerequisites

- AWS CLI v2 installed
- Access credentials for the management account
- Account IDs for all environments

## Quick Setup

### Option 1: Automated Setup (Recommended)

**Windows:**
```powershell
cd infrastructure/aws-cli
.\configure-aws-cli.ps1
```

**Linux/Mac:**
```bash
cd infrastructure/aws-cli
chmod +x configure-aws-cli.sh
./configure-aws-cli.sh
```

Follow the prompts to enter your credentials and account IDs.

### Option 2: Manual Setup

1. **Copy templates:**
   ```bash
   # Linux/Mac
   cp config.template ~/.aws/config
   cp credentials.template ~/.aws/credentials
   
   # Windows
   copy config.template %USERPROFILE%\.aws\config
   copy credentials.template %USERPROFILE%\.aws\credentials
   ```

2. **Edit the files and replace placeholders:**
   - `<YOUR_ACCESS_KEY_ID>` - Your IAM access key
   - `<YOUR_SECRET_ACCESS_KEY>` - Your IAM secret key
   - `<DEV_ACCOUNT_ID>` - Dev account ID
   - `<STAGING_ACCOUNT_ID>` - Staging account ID
   - `<PROD_ACCOUNT_ID>` - Prod account ID
   - `<SECURITY_ACCOUNT_ID>` - Security account ID
   - `<MANAGEMENT_ACCOUNT_ID>` - Management account ID
   - `<YOUR_USERNAME>` - Your IAM username (if using MFA)

3. **Secure the files:**
   ```bash
   # Linux/Mac
   chmod 600 ~/.aws/credentials
   chmod 600 ~/.aws/config
   ```

## Verify Setup

Run the validation script:

**Windows:**
```powershell
.\validate-aws-config.ps1
```

**Linux/Mac:**
```bash
chmod +x validate-aws-config.sh
./validate-aws-config.sh
```

Or test manually:
```bash
aws sts get-caller-identity --profile swasthyaai-dev
```

## Using Profiles

### Method 1: --profile flag
```bash
aws s3 ls --profile swasthyaai-dev
aws dynamodb list-tables --profile swasthyaai-staging
```

### Method 2: Environment variable
```bash
# Linux/Mac
export AWS_PROFILE=swasthyaai-dev
aws s3 ls

# Windows PowerShell
$env:AWS_PROFILE = "swasthyaai-dev"
aws s3 ls
```

### Method 3: Helper script
```bash
# Linux/Mac
source ./switch-profile.sh dev
aws s3 ls

# Windows PowerShell
.\switch-profile.ps1 dev
aws s3 ls
```

## Common Commands

```bash
# List S3 buckets
aws s3 ls --profile swasthyaai-dev

# List DynamoDB tables
aws dynamodb list-tables --profile swasthyaai-dev

# Get current identity
aws sts get-caller-identity --profile swasthyaai-dev

# List EC2 instances
aws ec2 describe-instances --profile swasthyaai-dev

# Deploy with Terraform
export AWS_PROFILE=swasthyaai-dev
terraform plan -var-file=environments/dev.tfvars
```

## Troubleshooting

### "Unable to locate credentials"
- Check that `~/.aws/credentials` exists and contains your access key
- Verify the profile name matches in both config and credentials files

### "AccessDenied when calling AssumeRole"
- Verify the role ARN is correct in `~/.aws/config`
- Check that the trust relationship allows your management account
- Ensure your IAM user has `sts:AssumeRole` permission

### "The security token is expired"
- Re-authenticate with MFA if enabled
- Run: `aws sts get-session-token --profile swasthyaai-management`

## Next Steps

- Read the full [README.md](README.md) for detailed documentation
- Review [AWS CLI best practices](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-files.html)
- Set up [AWS SSO](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-sso.html) for production

## Support

For issues or questions:
1. Check the [README.md](README.md) troubleshooting section
2. Review AWS CLI documentation
3. Contact the SwasthyaAI infrastructure team
