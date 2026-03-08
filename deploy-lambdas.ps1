# SwasthyaAI Lambda Deployment Script
# This script packages and uploads all Lambda functions with their dependencies

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "SwasthyaAI Lambda Deployment Script" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$ErrorActionPreference = "Stop"
$region = "us-east-1"

# Function to check if command exists
function Test-Command {
    param($Command)
    try {
        if (Get-Command $Command -ErrorAction Stop) {
            return $true
        }
    } catch {
        return $false
    }
}

# Check prerequisites
Write-Host "Checking prerequisites..." -ForegroundColor Yellow

if (-not (Test-Command "python")) {
    Write-Host "ERROR: Python is not installed or not in PATH" -ForegroundColor Red
    exit 1
}

# Check pip via python -m pip
try {
    python -m pip --version | Out-Null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: pip is not installed or not in PATH" -ForegroundColor Red
        exit 1
    }
} catch {
    Write-Host "ERROR: pip is not installed or not in PATH" -ForegroundColor Red
    exit 1
}

if (-not (Test-Command "node")) {
    Write-Host "ERROR: Node.js is not installed or not in PATH" -ForegroundColor Red
    exit 1
}

if (-not (Test-Command "npm")) {
    Write-Host "ERROR: npm is not installed or not in PATH" -ForegroundColor Red
    exit 1
}

if (-not (Test-Command "aws")) {
    Write-Host "ERROR: AWS CLI is not installed or not in PATH" -ForegroundColor Red
    exit 1
}

Write-Host "All prerequisites found!" -ForegroundColor Green
Write-Host ""

# Python Lambda Functions
$pythonFunctions = @(
    @{
        Name = "patient_chatbot"
        FunctionName = "swasthyaai-patient-chatbot-dev"
        Path = "backend/lambdas/patient_chatbot"
    },
    @{
        Name = "insurance_analyzer"
        FunctionName = "swasthyaai-insurance-analyzer-dev"
        Path = "backend/lambdas/insurance_analyzer"
    },
    @{
        Name = "clinical_summarizer_nova"
        FunctionName = "swasthyaai-clinical-summarizer-nova-dev"
        Path = "backend/lambdas/clinical_summarizer_nova"
    }
)

# Node.js Lambda Functions
$nodeFunctions = @(
    @{
        Name = "appointment_booking"
        FunctionName = "swasthyaai-appointment-booking-dev"
        Path = "backend/lambdas/appointment_booking"
    }
)

# Deploy Python Lambda Functions
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Deploying Python Lambda Functions" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

foreach ($func in $pythonFunctions) {
    Write-Host "Processing: $($func.Name)" -ForegroundColor Yellow
    Write-Host "  Path: $($func.Path)" -ForegroundColor Gray
    
    $funcPath = $func.Path
    $zipFile = "$funcPath/function.zip"
    
    # Remove old zip if exists
    if (Test-Path $zipFile) {
        Remove-Item $zipFile -Force
        Write-Host "  Removed old function.zip" -ForegroundColor Gray
    }
    
    # Create package directory
    $packageDir = "$funcPath/package"
    if (Test-Path $packageDir) {
        Remove-Item $packageDir -Recurse -Force
    }
    New-Item -ItemType Directory -Path $packageDir -Force | Out-Null
    
    # Install dependencies
    Write-Host "  Installing Python dependencies..." -ForegroundColor Gray
    if (Test-Path "$funcPath/requirements.txt") {
        python -m pip install -r "$funcPath/requirements.txt" -t $packageDir --quiet
        if ($LASTEXITCODE -ne 0) {
            Write-Host "  ERROR: Failed to install dependencies" -ForegroundColor Red
            continue
        }
    }
    
    # Copy handler
    Copy-Item "$funcPath/handler.py" -Destination $packageDir
    
    # Create zip
    Write-Host "  Creating deployment package..." -ForegroundColor Gray
    Push-Location $packageDir
    Compress-Archive -Path * -DestinationPath "../function.zip" -Force
    Pop-Location
    
    # Clean up package directory
    Remove-Item $packageDir -Recurse -Force
    
    # Upload to AWS Lambda
    Write-Host "  Uploading to AWS Lambda..." -ForegroundColor Gray
    aws lambda update-function-code `
        --function-name $func.FunctionName `
        --zip-file "fileb://$zipFile" `
        --region $region `
        --no-cli-pager | Out-Null
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  SUCCESS: $($func.Name) deployed!" -ForegroundColor Green
    } else {
        Write-Host "  ERROR: Failed to upload $($func.Name)" -ForegroundColor Red
    }
    
    Write-Host ""
}

# Deploy Node.js Lambda Functions
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Deploying Node.js Lambda Functions" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

foreach ($func in $nodeFunctions) {
    Write-Host "Processing: $($func.Name)" -ForegroundColor Yellow
    Write-Host "  Path: $($func.Path)" -ForegroundColor Gray
    
    $funcPath = $func.Path
    $zipFile = "$funcPath/function.zip"
    
    # Remove old zip if exists
    if (Test-Path $zipFile) {
        Remove-Item $zipFile -Force
        Write-Host "  Removed old function.zip" -ForegroundColor Gray
    }
    
    # Install dependencies
    Write-Host "  Installing Node.js dependencies..." -ForegroundColor Gray
    Push-Location $funcPath
    
    if (Test-Path "node_modules") {
        Remove-Item "node_modules" -Recurse -Force
    }
    
    npm install --production --quiet
    if ($LASTEXITCODE -ne 0) {
        Write-Host "  ERROR: Failed to install dependencies" -ForegroundColor Red
        Pop-Location
        continue
    }
    
    # Create zip
    Write-Host "  Creating deployment package..." -ForegroundColor Gray
    Compress-Archive -Path handler.js,node_modules,package.json -DestinationPath "function.zip" -Force
    
    Pop-Location
    
    # Upload to AWS Lambda
    Write-Host "  Uploading to AWS Lambda..." -ForegroundColor Gray
    aws lambda update-function-code `
        --function-name $func.FunctionName `
        --zip-file "fileb://$zipFile" `
        --region $region `
        --no-cli-pager | Out-Null
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "  SUCCESS: $($func.Name) deployed!" -ForegroundColor Green
    } else {
        Write-Host "  ERROR: Failed to upload $($func.Name)" -ForegroundColor Red
    }
    
    Write-Host ""
}

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Deployment Complete!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Test the Lambda functions using the AWS Console or CLI" -ForegroundColor White
Write-Host "2. Run: .\test-lambdas.ps1 to test all functions" -ForegroundColor White
Write-Host ""
