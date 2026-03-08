# Quick Backend Deployment Script
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "SwasthyaAI Backend Quick Deployment" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$ErrorActionPreference = "Stop"

# Step 1: Deploy Infrastructure
Write-Host "Step 1: Deploying Infrastructure with Terraform..." -ForegroundColor Yellow
Write-Host ""

Push-Location infrastructure

try {
    Write-Host "Running terraform init..." -ForegroundColor Gray
    terraform init -upgrade
    
    Write-Host "Running terraform plan..." -ForegroundColor Gray
    terraform plan -out=tfplan
    
    Write-Host "Running terraform apply..." -ForegroundColor Gray
    terraform apply tfplan
    
    Write-Host "  ✓ Infrastructure deployed successfully" -ForegroundColor Green
}
catch {
    Write-Host "  ✗ Infrastructure deployment failed" -ForegroundColor Red
    Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
    Pop-Location
    exit 1
}

Pop-Location
Write-Host ""

# Step 2: Deploy Lambda Functions
Write-Host "Step 2: Deploying Lambda Functions..." -ForegroundColor Yellow
Write-Host ""

.\deploy-new-lambdas.ps1

# Step 3: Verification
Write-Host ""
Write-Host "Step 3: Verifying Deployment..." -ForegroundColor Yellow
Write-Host ""

Write-Host "Checking Lambda functions..." -ForegroundColor Gray
$lambdas = aws lambda list-functions --region us-east-1 --query 'Functions[?starts_with(FunctionName, `swasthyaai`)].FunctionName' --output json | ConvertFrom-Json

Write-Host "  Found $($lambdas.Count) Lambda functions:" -ForegroundColor White
foreach ($lambda in $lambdas) {
    Write-Host "    - $lambda" -ForegroundColor Gray
}

Write-Host ""
Write-Host "Checking DynamoDB tables..." -ForegroundColor Gray
$tables = aws dynamodb list-tables --region us-east-1 --query 'TableNames[?starts_with(@, `swasthyaai`)]' --output json | ConvertFrom-Json

Write-Host "  Found $($tables.Count) DynamoDB tables:" -ForegroundColor White
foreach ($table in $tables) {
    Write-Host "    - $table" -ForegroundColor Gray
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Deployment Complete!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

Write-Host "API Base URL:" -ForegroundColor Yellow
Write-Host "  https://h5k89yezm6.execute-api.us-east-1.amazonaws.com/dev" -ForegroundColor Cyan
Write-Host ""

Write-Host "New Endpoints:" -ForegroundColor Yellow
Write-Host "  POST /auth/signup" -ForegroundColor White
Write-Host "  POST /auth/login" -ForegroundColor White
Write-Host "  GET  /auth/profile" -ForegroundColor White
Write-Host "  PUT  /auth/profile" -ForegroundColor White
Write-Host "  GET  /history/patient" -ForegroundColor White
Write-Host ""

Write-Host "Test Command:" -ForegroundColor Yellow
Write-Host '  Invoke-WebRequest -Uri "https://h5k89yezm6.execute-api.us-east-1.amazonaws.com/dev/auth/signup" -Method POST -Headers @{"Content-Type"="application/json"} -Body ''{"email":"test@test.com","password":"test123","name":"Test User","role":"patient"}''' -ForegroundColor Gray
Write-Host ""

Write-Host "Next Steps:" -ForegroundColor Yellow
Write-Host "  1. Test the new endpoints" -ForegroundColor White
Write-Host "  2. Update frontend to use real authentication" -ForegroundColor White
Write-Host "  3. Monitor CloudWatch Logs for any issues" -ForegroundColor White
Write-Host ""
