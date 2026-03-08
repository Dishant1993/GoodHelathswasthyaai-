# SwasthyaAI Backend Update Guide

## 🎯 Overview

This guide covers the deployment of enhanced backend functionality with real-time data integration for:
- User Authentication (Signup/Login)
- Patient History Management
- Enhanced SOAP Note Generation
- Real-time Insurance Checking

## 📋 New Features Implemented

### 1. Authentication System ✓
**Lambda:** `backend/lambdas/auth/handler.py`

**Endpoints:**
- `POST /auth/signup` - User registration
- `POST /auth/login` - User authentication
- `GET /auth/profile` - Get user profile
- `PUT /auth/profile` - Update user profile

**Features:**
- Password hashing with SHA-256
- Role-based registration (Doctor/Patient)
- Profile management
- DynamoDB storage

**Request Examples:**

```json
// Signup
POST /auth/signup
{
  "email": "doctor@example.com",
  "password": "securepassword",
  "name": "Dr. John Smith",
  "role": "doctor",
  "degree": "MBBS, MD",
  "experience": "15",
  "specialization": "Cardiology"
}

// Login
POST /auth/login
{
  "email": "doctor@example.com",
  "password": "securepassword"
}

// Update Profile
PUT /auth/profile
{
  "email": "doctor@example.com",
  "name": "Dr. John Smith",
  "degree": "MBBS, MD, FACC",
  "experience": "16"
}
```

### 2. Patient History Management ✓
**Lambda:** `backend/lambdas/patient_history/handler.py`

**Endpoints:**
- `GET /history/patient?patient_id=xxx` - Comprehensive patient history
- `GET /history/timeline?patient_id=xxx` - Patient timeline
- `GET /history/notes?patient_id=xxx` - Clinical notes
- `GET /history/appointments?patient_id=xxx` - Appointments

**Features:**
- Aggregates data from multiple sources
- Clinical notes with S3 download URLs
- Appointment categorization (upcoming/past)
- Timeline events tracking
- Real-time data retrieval

**Response Example:**

```json
{
  "patient_id": "patient123",
  "clinical_notes": [
    {
      "note_id": "note-uuid",
      "soap_note": {...},
      "confidence": 0.95,
      "created_at": "2026-03-08T10:00:00",
      "download_url": "https://s3.amazonaws.com/..."
    }
  ],
  "appointments": [
    {
      "appointment_id": "apt-uuid",
      "doctor_id": "dr001",
      "date": "2026-03-15",
      "time": "10:00",
      "status": "confirmed"
    }
  ],
  "timeline": [
    {
      "timestamp": "2026-03-08T10:00:00",
      "event_type": "clinical_note",
      "description": "Clinical note created"
    }
  ],
  "summary": {
    "total_notes": 5,
    "total_appointments": 3,
    "total_events": 12
  }
}
```

### 3. Enhanced SOAP Note Generation ✓
**Lambda:** `backend/lambdas/clinical_summarizer_nova/handler.py` (Updated)

**New Features:**
- DynamoDB storage for all generated notes
- Timeline event creation
- Note ID generation
- Persistent storage with S3 backup
- Real-time retrieval capability

**Request:**

```json
POST /clinical/generate
{
  "patient_id": "patient123",
  "clinical_text": "Patient presents with fever (101F), cough, and fatigue for 3 days...",
  "user_id": "dr001"
}
```

**Response:**

```json
{
  "note_id": "note-uuid-123",
  "soap_note": {
    "subjective": "Patient reports fever, cough, and fatigue for 3 days",
    "objective": "Temperature: 101F, Lungs: Clear, HR: 85",
    "assessment": "Upper respiratory infection",
    "plan": "Rest, fluids, acetaminophen for fever"
  },
  "confidence": 0.95,
  "entities_count": 13,
  "requires_review": false,
  "timestamp": "2026-03-08T10:00:00"
}
```

### 4. Real-time Insurance Checking ✓
**Lambda:** `backend/lambdas/insurance_analyzer/handler.py` (Updated)

**New Features:**
- DynamoDB storage for all checks
- Timeline event creation
- Check ID generation
- Historical check retrieval
- Real-time eligibility determination

**Request:**

```json
POST /insurance/analyze
{
  "patient_id": "patient123",
  "policy_key": "policies/patient123/policy.pdf",
  "procedure_code": "CPT-99213",
  "provider_network": {
    "hospital": "Apollo",
    "network": "PPO"
  }
}
```

**Response:**

```json
{
  "check_id": "check-uuid-123",
  "eligible": true,
  "coverage_percentage": 80,
  "explanation": "This procedure is covered under your policy...",
  "confidence": 0.85,
  "timestamp": "2026-03-08T10:00:00"
}
```

## 🗄️ Database Schema

### Users Table
**Table Name:** `swasthyaai-dev-users`
**Primary Key:** `email` (String)

**Attributes:**
- `user_id` (String) - UUID
- `email` (String) - Primary key
- `password_hash` (String) - SHA-256 hash
- `name` (String)
- `role` (String) - 'doctor' or 'patient'
- `created_at` (String) - ISO timestamp
- `updated_at` (String) - ISO timestamp

**Doctor-specific:**
- `degree` (String)
- `experience` (String)
- `specialization` (String)
- `phone` (String)

**Patient-specific:**
- `age` (String)
- `gender` (String)
- `phone` (String)
- `address` (String)
- `city` (String)
- `state` (String)
- `zip_code` (String)
- `blood_group` (String)

**Indexes:**
- `UserIdIndex` - GSI on `user_id`
- `RoleIndex` - GSI on `role`

### Insurance Checks Table
**Table Name:** `swasthyaai-dev-insurance-checks`
**Primary Key:** `check_id` (String)

**Attributes:**
- `check_id` (String) - UUID
- `patient_id` (String)
- `policy_key` (String)
- `procedure_code` (String)
- `provider_network` (Map)
- `result` (Map) - Analysis result
- `timestamp` (String)

**Indexes:**
- `PatientIndex` - GSI on `patient_id` + `timestamp`

## 🚀 Deployment Steps

### Step 1: Update Infrastructure

```powershell
cd infrastructure
terraform init
terraform plan
terraform apply
```

This will create:
- Users DynamoDB table
- Insurance Checks DynamoDB table
- Auth Lambda function
- Patient History Lambda function
- New API Gateway endpoints

### Step 2: Package and Deploy Lambdas

```powershell
# Deploy all new/updated Lambdas
.\deploy-new-lambdas.ps1
```

Or deploy individually:

```powershell
# Auth Lambda
cd backend/lambdas/auth
Compress-Archive -Path handler.py,requirements.txt -DestinationPath function.zip -Force
aws lambda update-function-code --function-name swasthyaai-auth-dev --zip-file fileb://function.zip --region us-east-1

# Patient History Lambda
cd backend/lambdas/patient_history
Compress-Archive -Path handler.py,requirements.txt -DestinationPath function.zip -Force
aws lambda update-function-code --function-name swasthyaai-patient-history-dev --zip-file fileb://function.zip --region us-east-1

# Clinical Summarizer (Updated)
cd backend/lambdas/clinical_summarizer_nova
Compress-Archive -Path handler.py,requirements.txt -DestinationPath function.zip -Force
aws lambda update-function-code --function-name swasthyaai-clinical-summarizer-nova-dev --zip-file fileb://function.zip --region us-east-1

# Insurance Analyzer (Updated)
cd backend/lambdas/insurance_analyzer
Compress-Archive -Path handler.py,requirements.txt -DestinationPath function.zip -Force
aws lambda update-function-code --function-name swasthyaai-insurance-analyzer-dev --zip-file fileb://function.zip --region us-east-1
```

### Step 3: Update API Gateway Deployment

```powershell
cd infrastructure
terraform apply -target=aws_api_gateway_deployment.swasthyaai_deployment
```

### Step 4: Test New Endpoints

```powershell
# Test Signup
Invoke-WebRequest -Uri "https://h5k89yezm6.execute-api.us-east-1.amazonaws.com/dev/auth/signup" `
  -Method POST `
  -Headers @{"Content-Type"="application/json"} `
  -Body '{"email":"test@example.com","password":"test123","name":"Test User","role":"patient"}'

# Test Login
Invoke-WebRequest -Uri "https://h5k89yezm6.execute-api.us-east-1.amazonaws.com/dev/auth/login" `
  -Method POST `
  -Headers @{"Content-Type"="application/json"} `
  -Body '{"email":"test@example.com","password":"test123"}'

# Test Patient History
Invoke-WebRequest -Uri "https://h5k89yezm6.execute-api.us-east-1.amazonaws.com/dev/history/patient?patient_id=patient123" `
  -Method GET
```

## 🔧 Environment Variables

### Auth Lambda
- `AWS_REGION` - us-east-1
- `USERS_TABLE` - swasthyaai-dev-users

### Patient History Lambda
- `AWS_REGION` - us-east-1
- `CLINICAL_NOTES_TABLE` - swasthyaai-dev-clinical-notes
- `APPOINTMENTS_TABLE` - swasthyaai-Appointments-dev
- `TIMELINE_TABLE` - swasthyaai-dev-timeline
- `CLINICAL_LOGS_BUCKET` - swasthyaai-clinical-logs-dev-348103269436

### Clinical Summarizer (Updated)
- `AWS_REGION` - us-east-1
- `CLINICAL_NOTES_TABLE` - swasthyaai-dev-clinical-notes
- `TIMELINE_TABLE` - swasthyaai-dev-timeline
- `LOGS_BUCKET` - swasthyaai-clinical-logs-dev-348103269436

### Insurance Analyzer (Updated)
- `AWS_REGION` - us-east-1
- `INSURANCE_TABLE` - swasthyaai-dev-insurance-checks
- `TIMELINE_TABLE` - swasthyaai-dev-timeline
- `POLICIES_BUCKET` - swasthyaai-insurance-policies-dev-348103269436
- `LOGS_BUCKET` - swasthyaai-insurance-logs-dev-348103269436

## 📊 API Endpoints Summary

| Endpoint | Method | Purpose | Status |
|----------|--------|---------|--------|
| `/auth/signup` | POST | User registration | ✅ New |
| `/auth/login` | POST | User authentication | ✅ New |
| `/auth/profile` | GET | Get user profile | ✅ New |
| `/auth/profile` | PUT | Update profile | ✅ New |
| `/history/patient` | GET | Get patient history | ✅ New |
| `/history/timeline` | GET | Get timeline | ✅ New |
| `/history/notes` | GET | Get clinical notes | ✅ New |
| `/history/appointments` | GET | Get appointments | ✅ New |
| `/clinical/generate` | POST | Generate SOAP note | ✅ Enhanced |
| `/insurance/analyze` | POST | Check insurance | ✅ Enhanced |
| `/chat` | POST | Patient chatbot | ✅ Existing |
| `/appointments/book` | POST | Book appointment | ✅ Existing |

## 🔐 Security Considerations

### Password Security
- Passwords are hashed using SHA-256
- Never stored in plain text
- Hashes are never returned in API responses

### Data Encryption
- All DynamoDB tables use KMS encryption
- S3 buckets use AES-256 encryption
- API Gateway uses TLS 1.2+

### Access Control
- Lambda functions have least-privilege IAM roles
- DynamoDB tables have fine-grained access control
- S3 buckets have bucket policies

## 🧪 Testing

### Test User Registration

```powershell
$signupBody = @{
    email = "doctor@test.com"
    password = "Test123!"
    name = "Dr. Test"
    role = "doctor"
    degree = "MBBS"
    experience = "10"
} | ConvertTo-Json

Invoke-WebRequest -Uri "$apiEndpoint/auth/signup" `
    -Method POST `
    -Headers @{"Content-Type"="application/json"} `
    -Body $signupBody
```

### Test Login

```powershell
$loginBody = @{
    email = "doctor@test.com"
    password = "Test123!"
} | ConvertTo-Json

Invoke-WebRequest -Uri "$apiEndpoint/auth/login" `
    -Method POST `
    -Headers @{"Content-Type"="application/json"} `
    -Body $loginBody
```

### Test Patient History

```powershell
Invoke-WebRequest -Uri "$apiEndpoint/history/patient?patient_id=test123" `
    -Method GET
```

## 📈 Monitoring

### CloudWatch Metrics
- Lambda invocations
- Error rates
- Duration
- DynamoDB read/write capacity

### CloudWatch Logs
- `/aws/lambda/swasthyaai-auth-dev`
- `/aws/lambda/swasthyaai-patient-history-dev`
- `/aws/lambda/swasthyaai-clinical-summarizer-nova-dev`
- `/aws/lambda/swasthyaai-insurance-analyzer-dev`

## 🐛 Troubleshooting

### Common Issues

**1. Lambda Function Not Found**
- Ensure Terraform apply completed successfully
- Check Lambda function exists in AWS Console

**2. DynamoDB Table Not Found**
- Run `terraform apply` to create tables
- Verify table names in environment variables

**3. Authentication Fails**
- Check password is correct
- Verify user exists in DynamoDB
- Check CloudWatch logs for errors

**4. Patient History Empty**
- Ensure patient_id is correct
- Check data exists in DynamoDB tables
- Verify GSI indexes are active

## 🎉 Summary

✅ **Authentication System** - Complete user management
✅ **Patient History** - Comprehensive data aggregation
✅ **Enhanced SOAP Notes** - Real-time storage and retrieval
✅ **Insurance Checking** - Persistent check history

All backend services now support real-time data with DynamoDB storage!

---

**Next Steps:**
1. Deploy infrastructure with Terraform
2. Package and deploy Lambda functions
3. Test all endpoints
4. Update frontend to use new APIs
5. Monitor CloudWatch for any issues
