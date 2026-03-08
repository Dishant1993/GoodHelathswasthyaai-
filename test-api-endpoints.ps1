# SwasthyaAI API Endpoint Testing Script
$API_BASE = "https://h5k89yezm6.execute-api.us-east-1.amazonaws.com/dev"

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "SwasthyaAI API Endpoint Testing" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Test 1: Signup
Write-Host "Test 1: User Signup" -ForegroundColor Yellow
$signupBody = @{
    email = "testuser@example.com"
    password = "Test123!"
    name = "Test User"
    role = "patient"
    age = "30"
    gender = "Male"
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "$API_BASE/auth/signup" -Method Post -Body $signupBody -ContentType "application/json"
    Write-Host "✓ Signup successful!" -ForegroundColor Green
    Write-Host ($response | ConvertTo-Json -Depth 10)
} catch {
    Write-Host "✗ Signup failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Test 2: Login
Write-Host "Test 2: User Login" -ForegroundColor Yellow
$loginBody = @{
    email = "testuser@example.com"
    password = "Test123!"
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "$API_BASE/auth/login" -Method Post -Body $loginBody -ContentType "application/json"
    Write-Host "✓ Login successful!" -ForegroundColor Green
    Write-Host ($response | ConvertTo-Json -Depth 10)
    $userId = $response.user.user_id
} catch {
    Write-Host "✗ Login failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Test 3: Get Profile
Write-Host "Test 3: Get User Profile" -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$API_BASE/auth/profile?email=testuser@example.com" -Method Get
    Write-Host "✓ Get profile successful!" -ForegroundColor Green
    Write-Host ($response | ConvertTo-Json -Depth 10)
} catch {
    Write-Host "✗ Get profile failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Test 4: Book Appointment
Write-Host "Test 4: Book Appointment" -ForegroundColor Yellow
$appointmentBody = @{
    patient_id = "testuser@example.com"
    doctor_id = "dr001"
    date = "2026-03-15"
    time = "10:00"
    reason = "General checkup"
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "$API_BASE/appointments/book" -Method Post -Body $appointmentBody -ContentType "application/json"
    Write-Host "✓ Appointment booked successfully!" -ForegroundColor Green
    Write-Host ($response | ConvertTo-Json -Depth 10)
} catch {
    Write-Host "✗ Appointment booking failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Test 5: Generate SOAP Note
Write-Host "Test 5: Generate SOAP Note" -ForegroundColor Yellow
$soapBody = @{
    patient_id = "testuser@example.com"
    clinical_data = "Patient complains of fever and cough for 3 days. Temperature 101F. Chest clear on auscultation."
    doctor_id = "dr001"
} | ConvertTo-Json

try {
    $response = Invoke-RestMethod -Uri "$API_BASE/clinical/generate" -Method Post -Body $soapBody -ContentType "application/json"
    Write-Host "✓ SOAP note generated successfully!" -ForegroundColor Green
    Write-Host ($response | ConvertTo-Json -Depth 10)
} catch {
    Write-Host "✗ SOAP note generation failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# Test 6: Get Patient History
Write-Host "Test 6: Get Patient History" -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$API_BASE/history/patient?patient_id=testuser@example.com" -Method Get
    Write-Host "✓ Patient history retrieved successfully!" -ForegroundColor Green
    Write-Host ($response | ConvertTo-Json -Depth 10)
} catch {
    Write-Host "✗ Patient history retrieval failed: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Testing Complete!" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Frontend URL: http://swasthyaai-frontend-dev-348103269436.s3-website-us-east-1.amazonaws.com" -ForegroundColor Cyan
Write-Host "API Base URL: $API_BASE" -ForegroundColor Cyan
