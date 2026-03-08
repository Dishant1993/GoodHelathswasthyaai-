# SwasthyaAI AWS CLI Configuration Validation Script (PowerShell)
# This script validates AWS CLI profiles and checks connectivity

param(
    [string]$Profile = "all",
    [switch]$Verbose
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
║     SwasthyaAI AWS CLI Validation Script                  ║
╚═══════════════════════════════════════════════════════════╝
"@ -ForegroundColor Cyan

# Check if AWS CLI is installed
Write-Info "`nChecking AWS CLI installation..."
try {
    $awsVersion = aws --version 2>&1
    Write-Success "✓ AWS CLI is installed: $awsVersion"
} catch {
    Write-Error "✗ AWS CLI is not installed!"
    exit 1
}

# Check if config files exist
$awsConfigDir = "$env:USERPROFILE\.aws"
$configFile = "$awsConfigDir\config"
$credentialsFile = "$awsConfigDir\credentials"

Write-Info "`nChecking configuration files..."
if (Test-Path $configFile) {
    Write-Success "✓ Config file exists: $configFile"
} else {
    Write-Error "✗ Config file not found: $configFile"
    exit 1
}

if (Test-Path $credentialsFile) {
    Write-Success "✓ Credentials file exists: $credentialsFile"
} else {
    Write-Error "✗ Credentials file not found: $credentialsFile"
    exit 1
}

# Define profiles to test
$allProfiles = @(
    "swasthyaai-management",
    "swasthyaai-dev",
    "swasthyaai-staging",
    "swasthyaai-prod",
    "swasthyaai-security"
)

$profilesToTest = if ($Profile -eq "all") {
    $allProfiles
} else {
    @("swasthyaai-$Profile")
}

# Validation tests
Write-Info "`nRunning validation tests..."
Write-Host ""

$results = @{}

foreach ($profileName in $profilesToTest) {
    Write-Host "="*60 -ForegroundColor Cyan
    Write-Host "Testing Profile: $profileName" -ForegroundColor Yellow
    Write-Host "="*60 -ForegroundColor Cyan
    
    $profileResults = @{
        "Profile" = $profileName
        "Identity" = $null
        "Region" = $null
        "S3Access" = $null
        "IAMAccess" = $null
        "OverallStatus" = "PASS"
    }
    
    # Test 1: Get caller identity
    Write-Info "`n[Test 1] Checking AWS identity..."
    try {
        $identityJson = aws sts get-caller-identity --profile $profileName 2>&1
        if ($LASTEXITCODE -eq 0) {
            $identity = $identityJson | ConvertFrom-Json
            Write-Success "  ✓ Identity verified"
            Write-Host "    User ID: $($identity.UserId)" -ForegroundColor Gray
            Write-Host "    Account: $($identity.Account)" -ForegroundColor Gray
            Write-Host "    ARN: $($identity.Arn)" -ForegroundColor Gray
            $profileResults["Identity"] = "PASS"
        } else {
            Write-Error "  ✗ Failed to get identity: $identityJson"
            $profileResults["Identity"] = "FAIL"
            $profileResults["OverallStatus"] = "FAIL"
        }
    } catch {
        Write-Error "  ✗ Exception: $($_.Exception.Message)"
        $profileResults["Identity"] = "FAIL"
        $profileResults["OverallStatus"] = "FAIL"
    }
    
    # Test 2: Check region configuration
    Write-Info "`n[Test 2] Checking region configuration..."
    try {
        $region = aws configure get region --profile $profileName 2>&1
        if ($LASTEXITCODE -eq 0 -and $region) {
            Write-Success "  ✓ Region configured: $region"
            $profileResults["Region"] = "PASS"
        } else {
            Write-Warning "  ⚠ Region not configured or using default"
            $profileResults["Region"] = "WARN"
        }
    } catch {
        Write-Warning "  ⚠ Could not determine region"
        $profileResults["Region"] = "WARN"
    }
    
    # Test 3: Test S3 access
    Write-Info "`n[Test 3] Testing S3 access..."
    try {
        $s3Result = aws s3 ls --profile $profileName 2>&1
        if ($LASTEXITCODE -eq 0) {
            $bucketCount = ($s3Result | Measure-Object).Count
            Write-Success "  ✓ S3 access verified ($bucketCount buckets)"
            if ($Verbose -and $bucketCount -gt 0) {
                Write-Host "    Buckets:" -ForegroundColor Gray
                $s3Result | ForEach-Object { Write-Host "      $_" -ForegroundColor Gray }
            }
            $profileResults["S3Access"] = "PASS"
        } else {
            Write-Warning "  ⚠ S3 access failed or no buckets: $s3Result"
            $profileResults["S3Access"] = "WARN"
        }
    } catch {
        Write-Warning "  ⚠ Could not test S3 access"
        $profileResults["S3Access"] = "WARN"
    }
    
    # Test 4: Test IAM access (list users)
    Write-Info "`n[Test 4] Testing IAM read access..."
    try {
        $iamResult = aws iam list-users --max-items 1 --profile $profileName 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Success "  ✓ IAM read access verified"
            $profileResults["IAMAccess"] = "PASS"
        } else {
            Write-Warning "  ⚠ IAM access limited or denied (this may be expected)"
            $profileResults["IAMAccess"] = "WARN"
        }
    } catch {
        Write-Warning "  ⚠ Could not test IAM access"
        $profileResults["IAMAccess"] = "WARN"
    }
    
    $results[$profileName] = $profileResults
    Write-Host ""
}

# Summary Report
Write-Host "`n" + "="*60 -ForegroundColor Cyan
Write-Host "Validation Summary Report" -ForegroundColor Cyan
Write-Host "="*60 -ForegroundColor Cyan

$summaryTable = @()
foreach ($profileName in $profilesToTest) {
    $result = $results[$profileName]
    $summaryTable += [PSCustomObject]@{
        Profile = $profileName
        Identity = $result["Identity"]
        Region = $result["Region"]
        S3 = $result["S3Access"]
        IAM = $result["IAMAccess"]
        Status = $result["OverallStatus"]
    }
}

$summaryTable | Format-Table -AutoSize

# Overall status
$passCount = ($results.Values | Where-Object { $_["OverallStatus"] -eq "PASS" }).Count
$totalCount = $results.Count

Write-Host ""
if ($passCount -eq $totalCount) {
    Write-Success "✓ All profiles validated successfully ($passCount/$totalCount)"
    Write-Host ""
    Write-Success "Your AWS CLI configuration is ready to use! 🎉"
} else {
    $failCount = $totalCount - $passCount
    Write-Warning "⚠ Some profiles failed validation ($failCount/$totalCount failed)"
    Write-Host ""
    Write-Info "Troubleshooting tips:"
    Write-Host "  1. Check your credentials in: $credentialsFile"
    Write-Host "  2. Verify account IDs in: $configFile"
    Write-Host "  3. Ensure MFA token is correct (if enabled)"
    Write-Host "  4. Check IAM role trust relationships"
    Write-Host "  5. Review the README.md troubleshooting section"
}

Write-Host ""
Write-Info "For detailed usage instructions, see: infrastructure/aws-cli/README.md"
