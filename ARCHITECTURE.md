# SwasthyaAI - System Architecture

## Overview

SwasthyaAI is a cloud-native healthcare platform built on AWS, leveraging serverless architecture and AI capabilities to provide clinical intelligence, patient management, and insurance analysis.

## Architecture Diagram

### Overall System Architecture
![SwasthyaAI Architecture](./generated-diagrams/diagram_b31e8349.png)

### Doctor Workflow
![Doctor Workflow](./generated-diagrams/diagram_430f4020.png)

### Patient Workflow
![Patient Workflow](./generated-diagrams/diagram_933f7d8e.png)

## Architecture Components

### 1. Frontend Layer

**Technology**: React + TypeScript + Material-UI

**Hosting**: Amazon S3 with static website hosting

**Features**:
- Responsive web application
- Role-based UI (Doctor/Patient views)
- Real-time API integration
- Client-side routing with React Router
- State management with Redux

**Key Pages**:
- Doctor Dashboard
- Patient Dashboard
- Appointment Booking
- Clinical Note Editor
- Insurance Checker
- Patient Reports
- Medical History

### 2. API Layer

**Service**: Amazon API Gateway (REST API)

**Configuration**:
- CORS enabled for cross-origin requests
- Request/Response validation
- API throttling and rate limiting
- Integration with Lambda functions

**Endpoints**:
```
/auth/*          - Authentication services
/appointments/*  - Appointment management
/clinical/*      - Clinical note generation
/insurance/*     - Insurance analysis
/chat/*          - Patient chatbot
/history/*       - Patient history
```

### 3. Backend Services (AWS Lambda)

All backend services are implemented as serverless Lambda functions:

#### 3.1 Authentication Service
- **Runtime**: Python 3.12
- **Function**: User signup, login, profile management
- **Features**:
  - Password encryption (bcrypt)
  - JWT token generation
  - Role-based access control
  - User profile CRUD operations

#### 3.2 Appointment Booking Service
- **Runtime**: Node.js 18
- **Function**: Appointment scheduling and management
- **Features**:
  - Real-time availability checking
  - Doctor-patient appointment matching
  - Appointment status tracking
  - Time slot management

#### 3.3 Clinical Summarizer Service
- **Runtime**: Python 3.12
- **Function**: AI-powered SOAP note generation
- **Features**:
  - Bedrock Nova Lite integration
  - Clinical data analysis
  - SOAP format generation
  - Medical terminology processing

#### 3.4 Insurance Analyzer Service
- **Runtime**: Python 3.12
- **Function**: Insurance policy coverage analysis
- **Features**:
  - Policy document retrieval from S3
  - AI-powered policy analysis
  - Coverage percentage calculation
  - Eligibility determination

#### 3.5 Patient Chatbot Service
- **Runtime**: Python 3.12
- **Function**: Conversational AI for patient queries
- **Features**:
  - Natural language processing
  - Context-aware responses
  - Medical information retrieval
  - Conversation history tracking

#### 3.6 Patient History Service
- **Runtime**: Python 3.12
- **Function**: Medical record management
- **Features**:
  - Timeline event tracking
  - Clinical notes storage
  - Appointment history
  - Medical report management

### 4. AI Services

**Service**: Amazon Bedrock (Nova Lite Model)

**Model ID**: `us.amazon.nova-lite-v1:0`

**Use Cases**:
1. **Clinical Note Generation**: Converts clinical data into structured SOAP notes
2. **Insurance Analysis**: Analyzes policy documents for coverage determination
3. **Patient Chatbot**: Provides intelligent responses to patient queries

**Configuration**:
- Temperature: 0.2 (for consistent, factual responses)
- Max Tokens: 1500
- Region: us-east-1

### 5. Data Storage Layer

#### 5.1 Amazon DynamoDB Tables

**Users Table**
- Primary Key: `user_id`
- Attributes: email, password_hash, name, role, profile_data
- Use: Store user accounts and profiles

**Appointments Table**
- Primary Key: `appointment_id`
- GSI: `DoctorDateIndex` (doctor_id, date)
- GSI: `PatientIndex` (patient_id)
- Use: Store appointment bookings

**Timeline Table**
- Primary Key: `patient_id`, Sort Key: `timestamp`
- Use: Store patient medical event timeline

**Insurance Checks Table**
- Primary Key: `check_id`
- Attributes: patient_id, policy_key, procedure_code, result
- Use: Store insurance eligibility checks

#### 5.2 Amazon S3 Buckets

**Frontend Bucket**
- Purpose: Host static React application
- Configuration: Static website hosting enabled
- Access: Public read access

**Insurance Policies Bucket**
- Purpose: Store insurance policy documents
- Configuration: Server-side encryption (AES256)
- Access: Private (Lambda access only)

**Clinical Logs Bucket**
- Purpose: Store clinical note generation logs
- Configuration: Versioning enabled, encrypted
- Access: Private (Lambda access only)

**Insurance Logs Bucket**
- Purpose: Store insurance analysis logs
- Configuration: Versioning enabled, encrypted
- Access: Private (Lambda access only)

**Conversations Bucket**
- Purpose: Store chatbot conversation history
- Configuration: Encrypted
- Access: Private (Lambda access only)

### 6. Security Layer

#### 6.1 IAM (Identity and Access Management)
- Lambda execution role with least privilege access
- S3 bucket policies for secure access
- DynamoDB table policies
- Bedrock model access permissions

#### 6.2 KMS (Key Management Service)
- Encryption keys for DynamoDB tables
- S3 bucket encryption
- Secrets encryption

#### 6.3 Security Features
- Password hashing with bcrypt
- HTTPS/TLS for all communications
- CORS configuration for API Gateway
- VPC endpoints for private communication (optional)

### 7. Monitoring & Logging

**Amazon CloudWatch**
- Lambda function logs
- API Gateway access logs
- Custom metrics for application monitoring
- Alarms for error rates and latency

**Log Groups**:
```
/aws/lambda/swasthyaai-auth-dev
/aws/lambda/swasthyaai-appointment-booking-dev
/aws/lambda/swasthyaai-clinical-summarizer-dev
/aws/lambda/swasthyaai-insurance-analyzer-dev
/aws/lambda/swasthyaai-patient-chatbot-dev
/aws/lambda/swasthyaai-patient-history-dev
```

## Data Flow Diagrams

### 1. User Authentication Flow
```
User → Frontend → API Gateway → Auth Lambda → DynamoDB (Users)
                                      ↓
                                  JWT Token
                                      ↓
                                  Frontend
```

### 2. Appointment Booking Flow
```
Patient → Frontend → API Gateway → Appointment Lambda → DynamoDB (Appointments)
                                           ↓
                                    Check Availability
                                           ↓
                                    Create Appointment
                                           ↓
                                    Update Timeline
```

### 3. Clinical Note Generation Flow
```
Doctor → Frontend → API Gateway → Clinical Lambda → Bedrock (Nova Lite)
                                         ↓                ↓
                                    S3 (Logs)      AI Analysis
                                         ↓                ↓
                                    DynamoDB      SOAP Note
                                    (Timeline)         ↓
                                                  Frontend
```

### 4. Insurance Analysis Flow
```
Patient → Frontend → API Gateway → Insurance Lambda → S3 (Policies)
                                          ↓                  ↓
                                    Retrieve Policy    Policy Text
                                          ↓                  ↓
                                    Bedrock (Nova Lite) ← ─ ┘
                                          ↓
                                    AI Analysis
                                          ↓
                                    DynamoDB (Insurance)
                                          ↓
                                    S3 (Logs)
                                          ↓
                                    Frontend (Result)
```

## Infrastructure as Code

**Tool**: Terraform

**Key Resources**:
- Lambda functions with deployment packages
- DynamoDB tables with GSIs
- S3 buckets with policies
- API Gateway with CORS
- IAM roles and policies
- CloudWatch log groups

**Deployment**:
```bash
cd infrastructure
terraform init
terraform plan
terraform apply
```

## Scalability

### Horizontal Scaling
- **Lambda**: Automatic scaling based on request volume
- **DynamoDB**: On-demand billing mode for automatic scaling
- **API Gateway**: Handles thousands of concurrent requests
- **S3**: Unlimited storage capacity

### Performance Optimization
- Lambda function memory: 1024 MB
- Lambda timeout: 60 seconds
- DynamoDB read/write capacity: On-demand
- API Gateway caching (optional)
- CloudFront CDN for frontend (optional)

## High Availability

- **Multi-AZ**: DynamoDB and S3 are multi-AZ by default
- **Serverless**: No server management required
- **Automatic Failover**: AWS handles infrastructure failures
- **Data Replication**: S3 versioning and DynamoDB backups

## Security Best Practices

1. **Encryption at Rest**: All data encrypted in DynamoDB and S3
2. **Encryption in Transit**: HTTPS/TLS for all communications
3. **Least Privilege**: IAM roles with minimal permissions
4. **Password Security**: Bcrypt hashing with salt
5. **API Security**: CORS configuration and rate limiting
6. **Audit Logging**: CloudWatch logs for all operations

## Cost Optimization

- **Serverless Architecture**: Pay only for what you use
- **On-Demand Pricing**: DynamoDB scales with usage
- **S3 Lifecycle Policies**: Archive old logs to Glacier
- **Lambda Memory Optimization**: Right-sized memory allocation
- **API Gateway Caching**: Reduce backend calls

## Disaster Recovery

- **Backup Strategy**: DynamoDB point-in-time recovery
- **S3 Versioning**: Recover deleted or modified objects
- **Multi-Region**: Can be deployed to multiple regions
- **Infrastructure as Code**: Quick recovery with Terraform

## Future Enhancements

1. **CloudFront CDN**: Add CDN for faster frontend delivery
2. **ElastiCache**: Add caching layer for frequently accessed data
3. **Step Functions**: Orchestrate complex workflows
4. **EventBridge**: Event-driven architecture for real-time updates
5. **Cognito**: Replace custom auth with AWS Cognito
6. **AppSync**: GraphQL API for real-time data sync
7. **SageMaker**: Custom ML models for specialized tasks
8. **QuickSight**: Analytics dashboard for insights

## Technology Stack Summary

| Layer | Technology | Purpose |
|-------|-----------|---------|
| Frontend | React + TypeScript | User interface |
| UI Framework | Material-UI | Component library |
| API | API Gateway | REST API endpoints |
| Compute | Lambda | Serverless functions |
| AI | Bedrock Nova Lite | AI/ML capabilities |
| Database | DynamoDB | NoSQL data storage |
| Storage | S3 | Object storage |
| Security | IAM + KMS | Access control & encryption |
| Monitoring | CloudWatch | Logs and metrics |
| IaC | Terraform | Infrastructure management |

## Deployment Architecture

```
Development Environment (dev)
├── Frontend: S3 bucket (swasthyaai-frontend-dev-*)
├── API: API Gateway (https://*.execute-api.us-east-1.amazonaws.com/dev)
├── Lambda: 6 functions (swasthyaai-*-dev)
├── DynamoDB: 4 tables (swasthyaai-dev-*)
└── S3: 4 buckets (swasthyaai-*-dev-*)

Production Environment (prod) - Future
├── Same structure with 'prod' suffix
├── Separate AWS account (recommended)
└── Additional security controls
```

## Conclusion

SwasthyaAI leverages AWS serverless architecture to provide a scalable, secure, and cost-effective healthcare platform. The use of AI services (Bedrock) enables intelligent features like clinical note generation and insurance analysis, while the serverless approach ensures high availability and automatic scaling.
