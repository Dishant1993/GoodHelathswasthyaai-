# SwasthyaAI Lambda Testing Script
# This script tests all deployed Lambda functions

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "SwasthyaAI Lambda Testing Script" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$ErrorActionPreference = "Stop"
$region = "us-east-1"

# Test 1: Patient Chatbot
Write-Host "Test 1: Patient Chatbot Lambda" -ForegroundColor Yellow
Write-Host "  Function: swasthyaai-patient-chatbot-dev" -ForegroundColor Gray

# Create payload file
$chatbotPayload = @{
    body = (@{
        query = "Hello, I have a headache. What should I do?"
        user_id = "test-user-123"
        history = @()
    } | ConvertTo-Json -Compress)
} | ConvertTo-Json -Compress

$chatbotPayload | Out-File -FilePath "payload-chatbot.json" -Encoding ascii -NoNewline

Write-Host "  Invoking Lambda..." -ForegroundColor Gray
try {
    aws lambda invoke --function-name swasthyaai-patient-chatbot-dev --payload file://payload-chatbot.json --region $region --cli-binary-format raw-in-base64-out response-chatbot.json | Out-Null
    
    if (Test-Path "response-chatbot.json") {
        Write-Host "  SUCCESS: Chatbot responded!" -ForegroundColor Green
        $response = Get-Content response-chatbot.json | ConvertFrom-Json
        Write-Host "  Status Code: $($response.statusCode)" -ForegroundColor Gray
        if ($response.statusCode -eq 200) {
            $body = $response.body | ConvertFrom-Json
            Write-Host "  Response Preview: $($body.response.Substring(0, [Math]::Min(100, $body.response.Length)))..." -ForegroundColor Gray
        } else {
            Write-Host "  Response Body: $($response.body)" -ForegroundColor Gray
        }
    }
} catch {
    Write-Host "  ERROR: Failed to invoke chatbot" -ForegroundColor Red
    Write-Host "  $($_.Exception.Message)" -ForegroundColor Red
}
Write-Host ""

# Test 2: Clinical Summarizer
Write-Host "Test 2: Clinical Summarizer Lambda" -ForegroundColor Yellow
Write-Host "  Function: swasthyaai-clinical-summarizer-nova-dev" -ForegroundColor Gray

# Create payload file
$clinicalPayload = @{
    body = (@{
        patient_id = "test-patient-456"
        clinical_text = "Patient presents with fever (101F), cough, and fatigue for 3 days. No shortness of breath. Vitals: BP 120/80, HR 85. Lungs clear. Diagnosis: Upper respiratory infection. Plan: Rest, fluids, acetaminophen for fever."
        user_id = "test-doctor-789"
    } | ConvertTo-Json -Compress)
} | ConvertTo-Json -Compress

$clinicalPayload | Out-File -FilePath "payload-clinical.json" -Encoding ascii -NoNewline

Write-Host "  Invoking Lambda..." -ForegroundColor Gray
try {
    aws lambda invoke --function-name swasthyaai-clinical-summarizer-nova-dev --payload file://payload-clinical.json --region $region --cli-binary-format raw-in-base64-out response-clinical.json | Out-Null
    
    if (Test-Path "response-clinical.json") {
        Write-Host "  SUCCESS: Clinical summarizer responded!" -ForegroundColor Green
        $response = Get-Content response-clinical.json | ConvertFrom-Json
        Write-Host "  Status Code: $($response.statusCode)" -ForegroundColor Gray
        if ($response.statusCode -eq 200) {
            $body = $response.body | ConvertFrom-Json
            Write-Host "  Confidence: $($body.confidence)" -ForegroundColor Gray
            Write-Host "  Entities Found: $($body.entities_count)" -ForegroundColor Gray
        } else {
            Write-Host "  Response Body: $($response.body)" -ForegroundColor Gray
        }
    }
} catch {
    Write-Host "  ERROR: Failed to invoke clinical summarizer" -ForegroundColor Red
    Write-Host "  $($_.Exception.Message)" -ForegroundColor Red
}
Write-Host ""

# Test 3: Appointment Booking
Write-Host "Test 3: Appointment Booking Lambda" -ForegroundColor Yellow
Write-Host "  Function: swasthyaai-appointment-booking-dev" -ForegroundColor Gray

# Create payload file
$appointmentPayload = @{
    httpMethod = "POST"
    path = "/appointments/book"
    body = (@{
        patient_id = "test-patient-456"
        doctor_id = "dr-smith-001"
        date = "2026-03-15"
        time = "10:00"
        reason = "Annual checkup"
    } | ConvertTo-Json -Compress)
} | ConvertTo-Json -Compress

$appointmentPayload | Out-File -FilePath "payload-appointment.json" -Encoding ascii -NoNewline

Write-Host "  Invoking Lambda..." -ForegroundColor Gray
try {
    aws lambda invoke --function-name swasthyaai-appointment-booking-dev --payload file://payload-appointment.json --region $region --cli-binary-format raw-in-base64-out response-appointment.json | Out-Null
    
    if (Test-Path "response-appointment.json") {
        Write-Host "  SUCCESS: Appointment booking responded!" -ForegroundColor Green
        $response = Get-Content response-appointment.json | ConvertFrom-Json
        Write-Host "  Status Code: $($response.statusCode)" -ForegroundColor Gray
        if ($response.statusCode -eq 200) {
            $body = $response.body | ConvertFrom-Json
            Write-Host "  Appointment ID: $($body.appointment_id)" -ForegroundColor Gray
            Write-Host "  Status: $($body.status)" -ForegroundColor Gray
        } else {
            Write-Host "  Response Body: $($response.body)" -ForegroundColor Gray
        }
    }
} catch {
    Write-Host "  ERROR: Failed to invoke appointment booking" -ForegroundColor Red
    Write-Host "  $($_.Exception.Message)" -ForegroundColor Red
}
Write-Host ""

# Test 4: Insurance Analyzer (requires S3 policy file)
Write-Host "Test 4: Insurance Analyzer Lambda" -ForegroundColor Yellow
Write-Host "  Function: swasthyaai-insurance-analyzer-dev" -ForegroundColor Gray
Write-Host "  NOTE: This test requires a policy file in S3" -ForegroundColor Gray
Write-Host "  Skipping for now - will test after uploading sample policy" -ForegroundColor Yellow
Write-Host ""

# Cleanup
Write-Host "Cleaning up test files..." -ForegroundColor Gray
if (Test-Path "payload-chatbot.json") { Remove-Item "payload-chatbot.json" -Force }
if (Test-Path "payload-clinical.json") { Remove-Item "payload-clinical.json" -Force }
if (Test-Path "payload-appointment.json") { Remove-Item "payload-appointment.json" -Force }
if (Test-Path "response-chatbot.json") { Remove-Item "response-chatbot.json" -Force }
if (Test-Path "response-clinical.json") { Remove-Item "response-clinical.json" -Force }
if (Test-Path "response-appointment.json") { Remove-Item "response-appointment.json" -Force }

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Testing Complete!" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Summary:" -ForegroundColor Yellow
Write-Host "- Patient Chatbot: Test completed" -ForegroundColor White
Write-Host "- Clinical Summarizer: Test completed" -ForegroundColor White
Write-Host "- Appointment Booking: Test completed" -ForegroundColor White
Write-Host "- Insurance Analyzer: Requires S3 policy file" -ForegroundColor White
Write-Host ""
Write-Host "Check the output above for any errors." -ForegroundColor Yellow
Write-Host "If all tests passed, your Lambda functions are working!" -ForegroundColor Green
Write-Host ""
