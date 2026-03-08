# SwasthyaAI AWS Profile Switcher (PowerShell)
# Quick helper script to switch between AWS profiles

param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("management", "dev", "staging", "prod", "security", "clear")]
    [string]$Environment
)

$PROFILES = @{
    "management" = "swasthyaai-management"
    "dev" = "swasthyaai-dev"
    "staging" = "swasthyaai-staging"
    "prod" = "swasthyaai-prod"
    "security" = "swasthyaai-security"
}

if ($Environment -eq "clear") {
    Remove-Item Env:\AWS_PROFILE -ErrorAction SilentlyContinue
    Write-Host "✓ AWS_PROFILE environment variable cleared" -ForegroundColor Green
    Write-Host "AWS CLI will now use default profile or --profile flag" -ForegroundColor Cyan
} else {
    $profileName = $PROFILES[$Environment]
    $env:AWS_PROFILE = $profileName
    
    Write-Host "✓ Switched to profile: $profileName" -ForegroundColor Green
    Write-Host ""
    Write-Host "Current AWS Identity:" -ForegroundColor Cyan
    
    try {
        $identity = aws sts get-caller-identity 2>&1 | ConvertFrom-Json
        Write-Host "  Account: $($identity.Account)" -ForegroundColor Gray
        Write-Host "  User: $($identity.Arn)" -ForegroundColor Gray
        Write-Host ""
        Write-Host "Environment: $Environment" -ForegroundColor Yellow
        Write-Host "Profile: $profileName" -ForegroundColor Yellow
    } catch {
        Write-Host "  Could not verify identity (you may need to authenticate)" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "Usage examples:" -ForegroundColor Cyan
Write-Host "  aws s3 ls" -ForegroundColor Gray
Write-Host "  aws dynamodb list-tables" -ForegroundColor Gray
Write-Host "  terraform plan" -ForegroundColor Gray
