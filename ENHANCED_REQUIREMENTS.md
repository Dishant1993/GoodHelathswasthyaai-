# SwasthyaAI Enhanced Requirements

## Project Overview
Build SwasthyaAI, an AI-powered healthcare ecosystem for patients and doctors using AWS services and Amazon Nova 2 Lite model.

---

## 1. Core Functionality

### 1.1 Patient Assistant (NEW)
- **Description**: Web-based AI chatbot for patients
- **Features**:
  - Understand medical reports
  - Check doctor availability
  - Book appointments
  - Natural language interaction
- **Technology**: Amazon Bedrock (Nova 2 Lite), React frontend

### 1.2 Provider Dashboard (EXISTING - ENHANCE)
- **Description**: AI-driven interface for doctors
- **Features**:
  - Generate clinical documentation in SOAP format
  - Confidence scoring (90%+ threshold)
  - Real-time AI assistance
- **Technology**: Amazon Bedrock (Nova 2 Lite), Material-UI

### 1.3 Insurance Logic (NEW)
- **Description**: AI module for insurance policy analysis
- **Features**:
  - Parse insurance policy PDFs
  - Compare against hospital provider networks
  - Determine reimbursement eligibility using RAG
- **Technology**: Amazon Bedrock (Nova 2 Lite), S3, RAG implementation

---

## 2. Technical Architecture

### 2.1 Compute
- **AWS Lambda** (Python 3.12)
  - Booking API handler
  - Insurance check handler
  - Clinical documentation generator
  - Patient chatbot handler

### 2.2 Storage
- **Amazon S3**
  - Static frontend hosting (React SPA)
  - Conversation logs (JSON)
  - Clinical summaries (JSON)
  - Insurance policy PDFs
  - Provider network data

### 2.3 AI/LLM
- **Amazon Bedrock**
  - Model: `amazon.nova-2-lite-v1:0`
  - Use cases:
    - Medical summaries
    - Chatbot responses
    - Insurance policy analysis
    - SOAP note generation

### 2.4 API
- **API Gateway**
  - REST API endpoints
  - CORS configuration
  - Lambda integration

---

## 3. Implementation Details

### 3.1 Frontend (Single Page Application)

#### Design Theme
- **Primary Color**: Deep Teal (#008B8B)
- **Secondary Color**: Warm Cream (#F5F5DC)
- **Typography**: Clean, accessible fonts
- **Layout**: Responsive, mobile-first

#### Components

**Sidebar Navigation**:
- Dashboard
- New Consultation
- Patient History
- AI Insights
- Reports
- Settings

**Main Content Area**:
- AI-Generated Clinical Documentation Card
  - Tab 1: Clinical Summary (SOAP format)
  - Tab 2: Patient Explanation (simplified)
  - Tab 3: Risk Indicators
  - Tab 4: Follow-up Plan

**Floating Action Button**:
- "View Patient Summary"

**Patient Chatbot Interface** (NEW):
- Chat window
- Medical report upload
- Appointment booking interface
- Doctor availability calendar

#### AI Integration
```javascript
// Example API call
const response = await fetch('https://api-gateway-url/chat', {
  method: 'POST',
  headers: { 'Content-Type': 'application/json' },
  body: JSON.stringify({ query: userMessage })
});
```

### 3.2 Backend (Lambda Functions)

#### Lambda 1: Clinical Documentation Generator
**File**: `backend/lambdas/clinical_documentation/handler.py`
```python
import boto3
import json
from datetime import datetime

bedrock = boto3.client('bedrock-runtime', region_name='ap-south-1')
s3 = boto3.client('s3')

SYSTEM_PROMPT = """You are a specialized medical assistant. 
Format clinical notes into S, O, A, and P sections with at least 
a 90% confidence score. Be concise and HIPAA-compliant."""

def lambda_handler(event, context):
    # Parse input
    body = json.loads(event['body'])
    clinical_data = body.get('clinical_data')
    user_id = body.get('user_id')
    
    # Call Bedrock Nova 2 Lite
    response = bedrock.invoke_model(
        modelId='amazon.nova-2-lite-v1:0',
        body=json.dumps({
            'messages': [
                {'role': 'system', 'content': SYSTEM_PROMPT},
                {'role': 'user', 'content': clinical_data}
            ],
            'temperature': 0.3,
            'max_tokens': 2000
        })
    )
    
    # Parse response
    result = json.loads(response['body'].read())
    soap_note = result['content'][0]['text']
    
    # Save to S3
    timestamp = datetime.utcnow().isoformat()
    log_data = {
        'timestamp': timestamp,
        'user_id': user_id,
        'query': clinical_data,
        'response': soap_note,
        'confidence': 0.95  # Calculate actual confidence
    }
    
    s3.put_object(
        Bucket='swasthyaai-clinical-logs',
        Key=f'logs/{user_id}/{timestamp}.json',
        Body=json.dumps(log_data),
        ServerSideEncryption='AES256'
    )
    
    return {
        'statusCode': 200,
        'headers': {
            'Access-Control-Allow-Origin': '*',
            'Content-Type': 'application/json'
        },
        'body': json.dumps({
            'soap_note': soap_note,
            'confidence': 0.95
        })
    }
```

#### Lambda 2: Patient Chatbot Handler (NEW)
**File**: `backend/lambdas/patient_chatbot/handler.py`
```python
import boto3
import json
from datetime import datetime

bedrock = boto3.client('bedrock-runtime', region_name='ap-south-1')
s3 = boto3.client('s3')

CHATBOT_PROMPT = """You are a helpful medical assistant for patients.
Help them understand medical reports, check doctor availability, and book appointments.
Be empathetic, clear, and avoid medical jargon. Always recommend consulting a doctor for serious concerns."""

def lambda_handler(event, context):
    body = json.loads(event['body'])
    user_query = body.get('query')
    user_id = body.get('user_id')
    conversation_history = body.get('history', [])
    
    # Build conversation context
    messages = [{'role': 'system', 'content': CHATBOT_PROMPT}]
    messages.extend(conversation_history)
    messages.append({'role': 'user', 'content': user_query})
    
    # Call Bedrock
    response = bedrock.invoke_model(
        modelId='amazon.nova-2-lite-v1:0',
        body=json.dumps({
            'messages': messages,
            'temperature': 0.7,
            'max_tokens': 1000
        })
    )
    
    result = json.loads(response['body'].read())
    bot_response = result['content'][0]['text']
    
    # Save conversation
    timestamp = datetime.utcnow().isoformat()
    log_data = {
        'timestamp': timestamp,
        'user_id': user_id,
        'query': user_query,
        'response': bot_response
    }
    
    s3.put_object(
        Bucket='swasthyaai-conversations',
        Key=f'chats/{user_id}/{timestamp}.json',
        Body=json.dumps(log_data),
        ServerSideEncryption='AES256'
    )
    
    return {
        'statusCode': 200,
        'headers': {
            'Access-Control-Allow-Origin': '*',
            'Content-Type': 'application/json'
        },
        'body': json.dumps({
            'response': bot_response,
            'timestamp': timestamp
        })
    }
```

#### Lambda 3: Insurance Policy Analyzer (NEW)
**File**: `backend/lambdas/insurance_analyzer/handler.py`
```python
import boto3
import json
from datetime import datetime

bedrock = boto3.client('bedrock-runtime', region_name='ap-south-1')
s3 = boto3.client('s3')

INSURANCE_PROMPT = """You are an insurance policy analyst.
Analyze the provided insurance policy and provider network data.
Determine reimbursement eligibility and coverage details.
Provide clear, structured output with confidence scores."""

def lambda_handler(event, context):
    body = json.loads(event['body'])
    policy_s3_key = body.get('policy_key')
    provider_network = body.get('provider_network')
    procedure_code = body.get('procedure_code')
    
    # Retrieve policy PDF from S3
    policy_obj = s3.get_object(
        Bucket='swasthyaai-insurance-policies',
        Key=policy_s3_key
    )
    policy_text = extract_text_from_pdf(policy_obj['Body'].read())
    
    # Build RAG context
    context = f"""
    Insurance Policy: {policy_text}
    Provider Network: {json.dumps(provider_network)}
    Procedure Code: {procedure_code}
    """
    
    # Call Bedrock with RAG
    response = bedrock.invoke_model(
        modelId='amazon.nova-2-lite-v1:0',
        body=json.dumps({
            'messages': [
                {'role': 'system', 'content': INSURANCE_PROMPT},
                {'role': 'user', 'content': context}
            ],
            'temperature': 0.2,
            'max_tokens': 1500
        })
    )
    
    result = json.loads(response['body'].read())
    analysis = result['content'][0]['text']
    
    return {
        'statusCode': 200,
        'headers': {
            'Access-Control-Allow-Origin': '*',
            'Content-Type': 'application/json'
        },
        'body': json.dumps({
            'analysis': analysis,
            'eligible': True,  # Parse from analysis
            'coverage_percentage': 80  # Parse from analysis
        })
    }

def extract_text_from_pdf(pdf_bytes):
    # Use PyPDF2 or similar library
    # For now, placeholder
    return "Policy text extracted from PDF"
```

#### Lambda 4: Appointment Booking Handler (NEW)
**File**: `backend/lambdas/appointment_booking/handler.py`
```python
import boto3
import json
from datetime import datetime

dynamodb = boto3.resource('dynamodb', region_name='ap-south-1')
appointments_table = dynamodb.Table('SwasthyaAI-Appointments')

def lambda_handler(event, context):
    body = json.loads(event['body'])
    patient_id = body.get('patient_id')
    doctor_id = body.get('doctor_id')
    appointment_date = body.get('date')
    appointment_time = body.get('time')
    
    # Check availability
    # Book appointment
    appointment_id = f"{patient_id}-{datetime.utcnow().timestamp()}"
    
    appointments_table.put_item(
        Item={
            'appointment_id': appointment_id,
            'patient_id': patient_id,
            'doctor_id': doctor_id,
            'date': appointment_date,
            'time': appointment_time,
            'status': 'confirmed',
            'created_at': datetime.utcnow().isoformat()
        }
    )
    
    return {
        'statusCode': 200,
        'headers': {
            'Access-Control-Allow-Origin': '*',
            'Content-Type': 'application/json'
        },
        'body': json.dumps({
            'appointment_id': appointment_id,
            'status': 'confirmed'
        })
    }
```

---

## 4. Data Security & Compliance

### 4.1 Encryption
- **At Rest**: S3 server-side encryption (AES-256)
- **In Transit**: HTTPS/TLS via API Gateway

### 4.2 IAM Roles (Least Privilege)
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "bedrock:InvokeModel"
      ],
      "Resource": "arn:aws:bedrock:ap-south-1::foundation-model/amazon.nova-2-lite-v1:0"
    },
    {
      "Effect": "Allow",
      "Action": [
        "s3:PutObject",
        "s3:GetObject"
      ],
      "Resource": "arn:aws:s3:::swasthyaai-*/*"
    }
  ]
}
```

### 4.3 CORS Configuration
```json
{
  "AllowOrigins": ["https://swasthyaai.com"],
  "AllowMethods": ["GET", "POST", "OPTIONS"],
  "AllowHeaders": ["Content-Type", "Authorization"],
  "MaxAge": 3600
}
```

### 4.4 HIPAA Compliance
- Audit logging enabled
- Data retention policies
- Access controls
- Encryption everywhere

---

## 5. Deployment Checklist

### Phase 1: Infrastructure
- [ ] Create S3 buckets (frontend, logs, policies)
- [ ] Set up API Gateway
- [ ] Configure IAM roles
- [ ] Enable Bedrock access

### Phase 2: Backend
- [ ] Deploy Lambda functions
- [ ] Configure environment variables
- [ ] Set up DynamoDB tables
- [ ] Test API endpoints

### Phase 3: Frontend
- [ ] Update UI with new theme
- [ ] Implement patient chatbot
- [ ] Add insurance checker
- [ ] Deploy to S3

### Phase 4: Testing
- [ ] End-to-end testing
- [ ] Security audit
- [ ] Performance testing
- [ ] HIPAA compliance review

---

## 6. API Endpoints

| Endpoint | Method | Lambda | Purpose |
|----------|--------|--------|---------|
| `/clinical/generate` | POST | clinical_documentation | Generate SOAP notes |
| `/chat` | POST | patient_chatbot | Patient chatbot |
| `/insurance/analyze` | POST | insurance_analyzer | Insurance eligibility |
| `/appointments/book` | POST | appointment_booking | Book appointments |
| `/appointments/availability` | GET | appointment_booking | Check availability |

---

## 7. Cost Estimation (Monthly)

- **Lambda**: ~$10 (1M requests)
- **Bedrock Nova 2 Lite**: ~$50 (based on usage)
- **S3**: ~$5 (storage + requests)
- **API Gateway**: ~$3.50 (1M requests)
- **DynamoDB**: ~$5 (on-demand)

**Total**: ~$73.50/month for moderate usage

---

## 8. Next Steps

1. Review and approve requirements
2. Set up AWS infrastructure
3. Implement Lambda functions
4. Update frontend with new features
5. Test and deploy

