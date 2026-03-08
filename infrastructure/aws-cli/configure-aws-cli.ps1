# SwasthyaAI AWS CLI Configuration Script (PowerShell)
# This script automates the setup of AWS CLI profiles for multi-account access

param(
    [switch]$SkipValidation,
    [switch]$UseSSO
)

$ErrorActionPreference = "Stop"

# Color output functions
function Write-Success { Write-Host $args -ForegroundColor Green }
function Write-Info { Write-Host $args -ForegroundColor Cyan }
function Write-Warning { Write-Host $args -ForegroundColor Yellow }
function Write-Error { Write-Host $args -ForegroundColor Red }

# Banner
Write-Host @"
╔═══════════════════════════════════════════════════════════╗
║     SwasthyaAI AWS CLI Configuration Script               ║
║     Multi-Account Setup for Dev, Staging, Prod            ║
╚═══════════════════════════════════════════════════════════╝
"@ -ForegroundColor Cyan

# Check if AWS CLI is installed
Write-Info "`n[1/7] Checking AWS CLI installation..."
try {
    $awsVersion = aws --version 2>&1
    Write-Success "✓ AWS CLI is installed: $awsVersion"
} catch {
    Write-Error "✗ AWS CLI is not installed!"
    Write-Info "Please install AWS CLI v2 from: https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html"
    exit 1
}

# Check AWS CLI version
if ($awsVersion -match "aws-cli/(\d+)\.") {
    $majorVersion = [int]$matches[1]
    if ($majorVersion -lt 2) {
        Write-Warning "⚠ AWS CLI v1 detected. We recommend upgrading to v2 for better features."
    }
}

# Create AWS config directory if it doesn't exist
$awsConfigDir = "$env:USERPROFILE\.aws"
if (-not (Test-Path $awsConfigDir)) {
    Write-Info "`n[2/7] Creating AWS configuration directory..."
    New-Item -ItemType Directory -Path $awsConfigDir -Force | Out-Null
    Write-Success "✓ Created directory: $awsConfigDir"
} else {
    Write-Success "`n[2/7] ✓ AWS configuration directory exists"
}

# Backup existing configuration
$configFile = "$awsConfigDir\config"
$credentialsFile = "$awsConfigDir\credentials"
$timestamp = Get-Date -Format "yyyyMMdd_HHmmss"

if (Test-Path $configFile) {
    Write-Info "`n[3/7] Backing up existing configuration..."
    Copy-Item $configFile "$configFile.backup.$timestamp"
    Write-Success "✓ Backed up config to: config.backup.$timestamp"
}

if (Test-Path $credentialsFile) {
    Copy-Item $credentialsFile "$credentialsFile.backup.$timestamp"
    Write-Success "✓ Backed up credentials to: credentials.backup.$timestamp"
}

if (-not (Test-Path $configFile) -and -not (Test-Path $credentialsFile)) {
    Write-Success "`n[3/7] ✓ No existing configuration to backup"
}

# Collect account information
Write-Info "`n[4/7] Collecting AWS account information..."
Write-Host ""

if ($UseSSO) {
    Write-Info "SSO Configuration Mode"
    Write-Host ""
    $ssoStartUrl = Read-Host "Enter your AWS SSO start URL"
    $ssoRegion = Read-Host "Enter SSO region (default: ap-south-1)" 
    if ([string]::IsNullOrWhiteSpace($ssoRegion)) { $ssoRegion = "ap-south-1" }
    
    Write-Info "`nConfiguring SSO profiles..."
    Write-Info "You will be prompted to authenticate via browser for each account."
    
    # Configure SSO for each environment
    $environments = @("dev", "staging", "prod", "security")
    foreach ($env in $environments) {
        Write-Info "`nConfiguring swasthyaai-$env profile..."
        aws configure sso --profile "swasthyaai-$env"
    }
    
    Write-Success "`n✓ SSO profiles configured"
} else {
    Write-Info "IAM User Configuration Mode"
    Write-Host ""
    
    # Management account credentials
    Write-Host "Management Account Credentials:" -ForegroundColor Yellow
    $managementAccessKey = Read-Host "Enter AWS Access Key ID for management account"
    $managementSecretKey = Read-Host "Enter AWS Secret Access Key for management account" -AsSecureString
    $managementSecretKeyPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto(
        [Runtime.InteropServices.Marshal]::SecureStringToBSTR($managementSecretKey)
    )
    
    # Account IDs
    Write-Host "`nAWS Account IDs:" -ForegroundColor Yellow
    $managementAccountId = Read-Host "Enter Management Account ID"
    $devAccountId = Read-Host "Enter Dev Account ID"
    $stagingAccountId = Read-Host "Enter Staging Account ID"
    $prodAccountId = Read-Host "Enter Prod Account ID"
    $securityAccountId = Read-Host "Enter Security Account ID"
    
    # MFA configuration
    Write-Host "`nMFA Configuration:" -ForegroundColor Yellow
    $useMFA = Read-Host "Do you want to enable MFA? (y/n)"
    $mfaSerial = ""
    if ($useMFA -eq "y") {
        $iamUsername = Read-Host "Enter your IAM username"
        $mfaSerial = "arn:aws:iam::${managementAccountId}:mfa/${iamUsername}"
        Write-Info "MFA Serial: $mfaSerial"
    }
    
    # Default region
    $defaultRegion = Read-Host "`nEnter default region (default: ap-south-1)"
    if ([string]::IsNullOrWhiteSpace($defaultRegion)) { $defaultRegion = "ap-south-1" }
    
    # Create credentials file
    Write-Info "`n[5/7] Creating credentials file..."
    $credentialsContent = @"
[swasthyaai-management]
aws_access_key_id = $managementAccessKey
aws_secret_access_key = $managementSecretKeyPlain
"@
    
    Set-Content -Path $credentialsFile -Value $credentialsContent -Force
    Write-Success "✓ Credentials file created"
    
    # Create config file
    Write-Info "`n[6/7] Creating config file..."
    $configContent = @"
[profile swasthyaai-management]
region = $defaultRegion
output = json

[profile swasthyaai-dev]
region = $defaultRegion
output = json
role_arn = arn:aws:iam::${devAccountId}:role/OrganizationAccountAccessRole
source_profile = swasthyaai-management
"@
    
    if ($useMFA -eq "y") {
        $configContent += "`nmfa_serial = $mfaSerial"
    }
    
    $configContent += @"

[profile swasthyaai-staging]
region = $defaultRegion
output = json
role_arn = arn:aws:iam::${stagingAccountId}:role/OrganizationAccountAccessRole
source_profile = swasthyaai-management
"@
    
    if ($useMFA -eq "y") {
        $configContent += "`nmfa_serial = $mfaSerial"
    }
    
    $configContent += @"

[profile swasthyaai-prod]
region = $defaultRegion
output = json
role_arn = arn:aws:iam::${prodAccountId}:role/OrganizationAccountAccessRole
source_profile = swasthyaai-management
"@
    
    if ($useMFA -eq "y") {
        $configContent += "`nmfa_serial = $mfaSerial"
    }
    
    $configContent += @"

[profile swasthyaai-security]
region = $defaultRegion
output = json
role_arn = arn:aws:iam::${securityAccountId}:role/OrganizationAccountAccessRole
source_profile = swasthyaai-management
"@
    
    if ($useMFA -eq "y") {
        $configContent += "`nmfa_serial = $mfaSerial"
    }
    
    Set-Content -Path $configFile -Value $configContent -Force
    Write-Success "✓ Config file created"
}

# Set secure permissions on credentials file
Write-Info "`nSecuring credentials file..."
$acl = Get-Acl $credentialsFile
$acl.SetAccessRuleProtection($true, $false)
$rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
    $env:USERNAME, "FullControl", "Allow"
)
$acl.SetAccessRule($rule)
Set-Acl $credentialsFile $acl
Write-Success "✓ Credentials file secured (only accessible by current user)"

# Validate configuration
if (-not $SkipValidation) {
    Write-Info "`n[7/7] Validating configuration..."
    Write-Host ""
    
    $profiles = @("swasthyaai-management", "swasthyaai-dev", "swasthyaai-staging", "swasthyaai-prod", "swasthyaai-security")
    $validationResults = @{}
    
    foreach ($profile in $profiles) {
        Write-Info "Testing profile: $profile"
        try {
            $result = aws sts get-caller-identity --profile $profile 2>&1
            if ($LASTEXITCODE -eq 0) {
                $identity = $result | ConvertFrom-Json
                Write-Success "  ✓ Success - Account: $($identity.Account)"
                $validationResults[$profile] = $true
            } else {
                Write-Error "  ✗ Failed - $result"
                $validationResults[$profile] = $false
            }
        } catch {
            Write-Error "  ✗ Failed - $($_.Exception.Message)"
            $validationResults[$profile] = $false
        }
    }
    
    # Summary
    Write-Host "`n" + "="*60 -ForegroundColor Cyan
    Write-Host "Validation Summary:" -ForegroundColor Cyan
    Write-Host "="*60 -ForegroundColor Cyan
    
    $successCount = ($validationResults.Values | Where-Object { $_ -eq $true }).Count
    $totalCount = $validationResults.Count
    
    foreach ($profile in $profiles) {
        $status = if ($validationResults[$profile]) { "✓ PASS" } else { "✗ FAIL" }
        $color = if ($validationResults[$profile]) { "Green" } else { "Red" }
        Write-Host "$status - $profile" -ForegroundColor $color
    }
    
    Write-Host "`nResults: $successCount/$totalCount profiles validated successfully" -ForegroundColor $(if ($successCount -eq $totalCount) { "Green" } else { "Yellow" })
} else {
    Write-Info "`n[7/7] Skipping validation (--SkipValidation flag used)"
}

# Final instructions
Write-Host "`n" + "="*60 -ForegroundColor Green
Write-Host "Configuration Complete!" -ForegroundColor Green
Write-Host "="*60 -ForegroundColor Green

Write-Host @"

Next Steps:
1. Test your configuration:
   aws sts get-caller-identity --profile swasthyaai-dev

2. Use profiles in commands:
   aws s3 ls --profile swasthyaai-dev

3. Set default profile (optional):
   `$env:AWS_PROFILE = "swasthyaai-dev"

4. Use helper scripts:
   .\switch-profile.ps1 dev

5. Review the README.md for detailed usage instructions

Configuration files location:
- Config: $configFile
- Credentials: $credentialsFile

Backup files (if any):
- Config backup: $configFile.backup.$timestamp
- Credentials backup: $credentialsFile.backup.$timestamp

"@ -ForegroundColor Cyan

Write-Success "Setup completed successfully! 🎉"
