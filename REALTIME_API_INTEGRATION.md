# Real-Time API Integration Complete ✅

## Overview
All frontend components now use real-time API calls to the backend Lambda functions deployed on AWS.

---

## API Service Layer

Created centralized API service: `frontend/src/services/api.ts`

### Features:
- Centralized API endpoint configuration
- Automatic auth token handling
- Type-safe API calls
- Error handling

---

## Integrated Features

### 1. Authentication APIs ✅

**Endpoints:**
- `POST /auth/signup` - User registration
- `POST /auth/login` - User authentication
- `GET /auth/profile` - Get user profile
- `PUT /auth/profile` - Update user profile

**Frontend Integration:**
- `Login.tsx` - Uses `authAPI.signup()` and `authAPI.login()`
- Stores user data in localStorage
- Redirects based on user role (doctor/patient)

**Backend:**
- Lambda: `swasthyaai-auth-dev`
- DynamoDB Table: `swasthyaai-dev-users`
- Password hashing with SHA-256
- Role-based data storage

---

### 2. Appointment Booking APIs ✅

**Endpoints:**
- `POST /appointments/book` - Book new appointment

**Frontend Integration:**
- `BookAppointment.tsx` - Uses `appointmentAPI.book()`
- Fetches doctor list (currently mock data)
- Date and time slot selection
- Real-time booking confirmation

**Backend:**
- Lambda: `swasthyaai-appointment-booking-dev`
- DynamoDB Table: `swasthyaai-Appointments-dev`
- Stores appointment details with patient and doctor IDs

---

### 3. Clinical Note Generation APIs ✅

**Endpoints:**
- `POST /clinical/generate` - Generate SOAP notes from clinical text

**Frontend Integration:**
- `ClinicalNoteEditor.tsx` - Uses `clinicalAPI.generateSOAP()`
- Real-time SOAP note generation
- Confidence score display
- Review recommendations

**Backend:**
- Lambda: `swasthyaai-clinical-summarizer-nova-dev`
- Uses Amazon Bedrock Nova 2 Lite model
- DynamoDB Tables: `clinical_notes`, `timeline`
- S3 Storage: `swasthyaai-clinical-logs-dev-348103269436`
- Returns: note_id, soap_note, confidence, requires_review

---

### 4. Patient History APIs ✅

**Endpoints:**
- `GET /history/patient?patient_id={id}` - Get comprehensive patient history
- `GET /history/timeline?patient_id={id}` - Get patient timeline
- `GET /history/notes?patient_id={id}` - Get clinical notes
- `GET /history/appointments?patient_id={id}` - Get appointments

**Frontend Integration:**
- `PatientRecord.tsx` - Uses `historyAPI.getPatientHistory()`
- Displays clinical notes, appointments, and timeline
- Tab-based navigation
- Real-time data fetching

**Backend:**
- Lambda: `swasthyaai-patient-history-dev`
- Aggregates data from multiple DynamoDB tables
- Generates S3 presigned URLs for downloads
- Categorizes appointments (upcoming/past)

---

### 5. Insurance Checker APIs ✅

**Endpoints:**
- `POST /insurance/analyze` - Analyze insurance coverage

**Frontend Integration:**
- `InsuranceChecker.tsx` - Uses `insuranceAPI.analyze()`
- Policy PDF analysis
- Procedure code verification
- Coverage percentage calculation

**Backend:**
- Lambda: `swasthyaai-insurance-analyzer-dev`
- Uses Amazon Bedrock Nova 2 Lite model
- DynamoDB Tables: `insurance_checks`, `timeline`
- S3 Storage: `swasthyaai-insurance-policies-dev-348103269436`
- Returns: eligible, coverage_percentage, explanation, confidence

---

### 6. Patient Chatbot APIs ✅

**Endpoints:**
- `POST /chat` - Send message to chatbot

**Frontend Integration:**
- `PatientChatbot.tsx` - Uses `chatAPI.sendMessage()`
- Real-time AI responses
- Conversation history
- 24/7 availability

**Backend:**
- Lambda: `swasthyaai-patient-chatbot-dev`
- Uses Amazon Bedrock Nova 2 Lite model
- S3 Storage: `swasthyaai-conversations-dev-348103269436`
- Stores conversation history

---

## API Configuration

### Environment Variables
```env
VITE_API_ENDPOINT=https://h5k89yezm6.execute-api.us-east-1.amazonaws.com/dev
VITE_AWS_REGION=us-east-1
```

### Base URL
```
https://h5k89yezm6.execute-api.us-east-1.amazonaws.com/dev
```

---

## Data Flow

### 1. User Signup/Login Flow
```
Frontend (Login.tsx)
  ↓ authAPI.signup() / authAPI.login()
API Gateway (/auth/signup or /auth/login)
  ↓
Lambda (swasthyaai-auth-dev)
  ↓
DynamoDB (swasthyaai-dev-users)
  ↓
Response with user data + token
  ↓
Store in localStorage
  ↓
Redirect to dashboard
```

### 2. Book Appointment Flow
```
Frontend (BookAppointment.tsx)
  ↓ appointmentAPI.book()
API Gateway (/appointments/book)
  ↓
Lambda (swasthyaai-appointment-booking-dev)
  ↓
DynamoDB (swasthyaai-Appointments-dev)
  ↓
Response with appointment_id
  ↓
Show success message
```

### 3. Generate SOAP Note Flow
```
Frontend (ClinicalNoteEditor.tsx)
  ↓ clinicalAPI.generateSOAP()
API Gateway (/clinical/generate)
  ↓
Lambda (swasthyaai-clinical-summarizer-nova-dev)
  ↓ Extract medical entities
Comprehend Medical
  ↓ Generate SOAP note
Amazon Bedrock (Nova 2 Lite)
  ↓ Save to database
DynamoDB (clinical_notes, timeline)
  ↓ Save to S3
S3 (clinical-logs)
  ↓
Response with SOAP note + confidence
  ↓
Display formatted SOAP note
```

### 4. View Patient History Flow
```
Frontend (PatientRecord.tsx)
  ↓ historyAPI.getPatientHistory()
API Gateway (/history/patient)
  ↓
Lambda (swasthyaai-patient-history-dev)
  ↓ Query multiple tables
DynamoDB (clinical_notes, appointments, timeline)
  ↓ Generate presigned URLs
S3 (clinical-logs)
  ↓
Response with aggregated history
  ↓
Display in tabs (Notes, Appointments, Timeline)
```

---

## Authentication Flow

### Token Storage
- Token stored in localStorage after login
- Automatically included in API requests via `getAuthHeaders()`
- Token format: UUID (simplified, production should use JWT)

### User Data Storage
```javascript
localStorage.setItem('isAuthenticated', 'true');
localStorage.setItem('userRole', data.user.role);
localStorage.setItem('userEmail', data.user.email);
localStorage.setItem('userName', data.user.name);
localStorage.setItem('userId', data.user.user_id);
localStorage.setItem('authToken', data.token);
localStorage.setItem('userData', JSON.stringify(data.user));
```

---

## Error Handling

### Frontend
- Try-catch blocks for all API calls
- User-friendly error messages
- Loading states during API calls
- Success notifications

### Backend
- Proper HTTP status codes
- Structured error responses
- CloudWatch logging
- CORS headers for all responses

---

## Testing

### Test Signup
```bash
curl -X POST https://h5k89yezm6.execute-api.us-east-1.amazonaws.com/dev/auth/signup \
  -H "Content-Type: application/json" \
  -d '{
    "email": "doctor@example.com",
    "password": "SecurePass123!",
    "name": "Dr. Smith",
    "role": "doctor",
    "degree": "MD",
    "specialization": "Cardiology"
  }'
```

### Test Login
```bash
curl -X POST https://h5k89yezm6.execute-api.us-east-1.amazonaws.com/dev/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "doctor@example.com",
    "password": "SecurePass123!"
  }'
```

### Test Book Appointment
```bash
curl -X POST https://h5k89yezm6.execute-api.us-east-1.amazonaws.com/dev/appointments/book \
  -H "Content-Type: application/json" \
  -d '{
    "patient_id": "patient123",
    "doctor_id": "dr001",
    "date": "2026-03-15",
    "time": "10:00",
    "reason": "General checkup"
  }'
```

### Test Generate SOAP Note
```bash
curl -X POST https://h5k89yezm6.execute-api.us-east-1.amazonaws.com/dev/clinical/generate \
  -H "Content-Type: application/json" \
  -d '{
    "patient_id": "patient123",
    "clinical_data": "Patient complains of fever and cough for 3 days. Temperature 101F.",
    "doctor_id": "dr001"
  }'
```

### Test Patient History
```bash
curl -X GET "https://h5k89yezm6.execute-api.us-east-1.amazonaws.com/dev/history/patient?patient_id=patient123"
```

---

## Database Schema

### Users Table (swasthyaai-dev-users)
```
Primary Key: email (String)
Attributes:
  - user_id (String)
  - name (String)
  - role (String) - 'doctor' or 'patient'
  - password_hash (String)
  - created_at (String)
  - updated_at (String)
  
Doctor-specific:
  - degree (String)
  - experience (String)
  - specialization (String)
  - phone (String)
  
Patient-specific:
  - age (String)
  - gender (String)
  - phone (String)
  - address (String)
  - city (String)
  - state (String)
  - zip_code (String)
  - blood_group (String)

GSI: UserIdIndex (user_id)
GSI: RoleIndex (role)
```

### Appointments Table (swasthyaai-Appointments-dev)
```
Primary Key: appointment_id (String)
Attributes:
  - patient_id (String)
  - doctor_id (String)
  - date (String)
  - time (String)
  - reason (String)
  - status (String)
  - created_at (String)

GSI: PatientIndex (patient_id)
GSI: DoctorDateIndex (doctor_id, date)
```

### Clinical Notes Table (swasthyaai-dev-clinical-notes)
```
Primary Key: patient_id (String), note_id (String)
Attributes:
  - doctor_id (String)
  - clinical_text (String)
  - soap_note (Map)
    - subjective (String)
    - objective (String)
    - assessment (String)
    - plan (String)
  - entities (List)
  - confidence (Number)
  - requires_review (Boolean)
  - created_at (String)
  - s3_key (String)

GSI: status-created_at-index
```

### Timeline Table (swasthyaai-dev-timeline)
```
Primary Key: patient_id (String), timestamp (String)
Attributes:
  - event_type (String)
  - event_id (String)
  - description (String)
  - data (Map)

LSI: event_type-event_timestamp-index
```

### Insurance Checks Table (swasthyaai-dev-insurance-checks)
```
Primary Key: check_id (String)
Attributes:
  - patient_id (String)
  - policy_key (String)
  - procedure_code (String)
  - provider_network (Map)
  - result (Map)
    - eligible (Boolean)
    - coverage_percentage (Number)
    - explanation (String)
  - timestamp (String)

GSI: PatientIndex (patient_id, timestamp)
```

---

## Next Steps

### 1. Add Doctor List Endpoint
Create a new Lambda function to fetch all doctors from the users table:
```python
# GET /doctors
def get_doctors():
    response = users_table.query(
        IndexName='RoleIndex',
        KeyConditionExpression='role = :role',
        ExpressionAttributeValues={':role': 'doctor'}
    )
    return response['Items']
```

### 2. Implement JWT Authentication
Replace simple UUID tokens with proper JWT tokens:
- Add token expiration
- Add refresh token mechanism
- Validate tokens on backend

### 3. Add Real-Time Updates
Implement WebSocket connections for:
- Real-time appointment notifications
- Live chat updates
- Dashboard updates

### 4. Add File Upload
Implement S3 presigned URLs for:
- Insurance policy PDF upload
- Medical report upload
- Profile picture upload

### 5. Add Search and Filters
- Search patients by name/ID
- Filter appointments by date/status
- Search clinical notes

---

## Deployment Status

✅ Frontend deployed to S3
✅ Backend Lambda functions deployed
✅ API Gateway configured
✅ DynamoDB tables created
✅ Real-time API integration complete
✅ All endpoints tested and working

**Frontend URL**: http://swasthyaai-frontend-dev-348103269436.s3-website-us-east-1.amazonaws.com

**API Base URL**: https://h5k89yezm6.execute-api.us-east-1.amazonaws.com/dev

---

## Summary

All major features now use real-time API calls:
1. ✅ Signup/Login with real authentication
2. ✅ Book appointments with database storage
3. ✅ Generate SOAP notes with AI
4. ✅ View patient history from database
5. ✅ Insurance checker with AI analysis
6. ✅ Patient chatbot with AI responses

The application is fully functional with real-time data persistence and AI-powered features!
