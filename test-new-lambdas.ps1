# Test script for new Lambda functions
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "SwasthyaAI New Lambda Testing Script" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Test 1: Auth Signup
Write-Host "Test 1: Auth Signup Lambda" -ForegroundColor Yellow
Write-Host "Function: swasthyaai-auth-dev" -ForegroundColor Gray
Write-Host "Invoking Lambda..." -ForegroundColor Gray

$signupPayload = @{
    body = @{
        email = "test@example.com"
        password = "Test123!"
        name = "Test User"
        role = "patient"
        age = "30"
        gender = "Male"
        phone = "1234567890"
    } | ConvertTo-Json
} | ConvertTo-Json

$signupResult = aws lambda invoke `
    --function-name swasthyaai-auth-dev `
    --payload $signupPayload `
    --cli-binary-format raw-in-base64-out `
    response-signup.json 2>&1

if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Lambda invoked successfully" -ForegroundColor Green
    Write-Host "Response:" -ForegroundColor Gray
    Get-Content response-signup.json | ConvertFrom-Json | ConvertTo-Json -Depth 10
} else {
    Write-Host "✗ Lambda invocation failed" -ForegroundColor Red
    Write-Host $signupResult -ForegroundColor Red
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Test 2: Auth Login
Write-Host "Test 2: Auth Login Lambda" -ForegroundColor Yellow
Write-Host "Function: swasthyaai-auth-dev" -ForegroundColor Gray
Write-Host "Invoking Lambda..." -ForegroundColor Gray

$loginPayload = @{
    body = @{
        email = "test@example.com"
        password = "Test123!"
    } | ConvertTo-Json
} | ConvertTo-Json

$loginResult = aws lambda invoke `
    --function-name swasthyaai-auth-dev `
    --payload $loginPayload `
    --cli-binary-format raw-in-base64-out `
    response-login.json 2>&1

if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Lambda invoked successfully" -ForegroundColor Green
    Write-Host "Response:" -ForegroundColor Gray
    Get-Content response-login.json | ConvertFrom-Json | ConvertTo-Json -Depth 10
} else {
    Write-Host "✗ Lambda invocation failed" -ForegroundColor Red
    Write-Host $loginResult -ForegroundColor Red
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Test 3: Patient History
Write-Host "Test 3: Patient History Lambda" -ForegroundColor Yellow
Write-Host "Function: swasthyaai-patient-history-dev" -ForegroundColor Gray
Write-Host "Invoking Lambda..." -ForegroundColor Gray

$historyPayload = @{
    queryStringParameters = @{
        patient_id = "test-patient-123"
    }
} | ConvertTo-Json

$historyResult = aws lambda invoke `
    --function-name swasthyaai-patient-history-dev `
    --payload $historyPayload `
    --cli-binary-format raw-in-base64-out `
    response-history.json 2>&1

if ($LASTEXITCODE -eq 0) {
    Write-Host "✓ Lambda invoked successfully" -ForegroundColor Green
    Write-Host "Response:" -ForegroundColor Gray
    Get-Content response-history.json | ConvertFrom-Json | ConvertTo-Json -Depth 10
} else {
    Write-Host "✗ Lambda invocation failed" -ForegroundColor Red
    Write-Host $historyResult -ForegroundColor Red
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Testing Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "API Gateway URL: https://h5k89yezm6.execute-api.us-east-1.amazonaws.com/dev" -ForegroundColor Cyan
Write-Host ""
Write-Host "Available Endpoints:" -ForegroundColor Yellow
Write-Host "  POST /auth/signup" -ForegroundColor Gray
Write-Host "  POST /auth/login" -ForegroundColor Gray
Write-Host "  GET  /auth/profile?email=<email>" -ForegroundColor Gray
Write-Host "  PUT  /auth/profile" -ForegroundColor Gray
Write-Host "  GET  /history/patient?patient_id=<id>" -ForegroundColor Gray
Write-Host ""
