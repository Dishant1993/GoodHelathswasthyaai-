# Deploy New Lambda Functions Script
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Deploying New Lambda Functions" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$region = "us-east-1"
$ErrorActionPreference = "Continue"

# Function to deploy a Lambda
function Deploy-Lambda {
    param(
        [string]$FunctionName,
        [string]$Path
    )
    
    Write-Host "Deploying $FunctionName..." -ForegroundColor Yellow
    
    try {
        # Create zip file
        Push-Location $Path
        
        if (Test-Path "function.zip") {
            Remove-Item "function.zip" -Force
        }
        
        Compress-Archive -Path handler.py,requirements.txt -DestinationPath function.zip -Force
        
        # Update Lambda function
        aws lambda update-function-code `
            --function-name $FunctionName `
            --zip-file fileb://function.zip `
            --region $region | Out-Null
        
        Write-Host "  ✓ $FunctionName deployed successfully" -ForegroundColor Green
        
        Pop-Location
    }
    catch {
        Write-Host "  ✗ Failed to deploy $FunctionName" -ForegroundColor Red
        Write-Host "  Error: $($_.Exception.Message)" -ForegroundColor Red
        Pop-Location
    }
}

# Deploy Auth Lambda
Deploy-Lambda -FunctionName "swasthyaai-auth-dev" -Path "backend/lambdas/auth"

# Deploy Patient History Lambda
Deploy-Lambda -FunctionName "swasthyaai-patient-history-dev" -Path "backend/lambdas/patient_history"

# Update Clinical Summarizer
Deploy-Lambda -FunctionName "swasthyaai-clinical-summarizer-nova-dev" -Path "backend/lambdas/clinical_summarizer_nova"

# Update Insurance Analyzer
Deploy-Lambda -FunctionName "swasthyaai-insurance-analyzer-dev" -Path "backend/lambdas/insurance_analyzer"

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Deployment Complete!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "New API Endpoints:" -ForegroundColor Yellow
Write-Host "  POST /auth/signup - User registration" -ForegroundColor White
Write-Host "  POST /auth/login - User authentication" -ForegroundColor White
Write-Host "  GET  /auth/profile - Get user profile" -ForegroundColor White
Write-Host "  PUT  /auth/profile - Update user profile" -ForegroundColor White
Write-Host "  GET  /history/patient - Get patient history" -ForegroundColor White
Write-Host ""
Write-Host "Updated Endpoints:" -ForegroundColor Yellow
Write-Host "  POST /clinical/generate - Enhanced with DynamoDB storage" -ForegroundColor White
Write-Host "  POST /insurance/analyze - Enhanced with real-time data" -ForegroundColor White
Write-Host ""
