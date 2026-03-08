# SwasthyaAI - Comprehensive Architecture Diagram Guide

## 📊 Diagram Overview

**File:** `swasthyaai_comprehensive_architecture.png`

**Title:** SwasthyaAI - AI Powered Clinical Intelligence Platform (AWS Architecture)

This is a single, comprehensive AWS architecture diagram that shows all layers, components, and data flows for the SwasthyaAI healthcare AI solution.

---

## 🎯 Purpose

SwasthyaAI is designed to:
- **Reduce doctor documentation burden** through AI-powered summarization
- **Maintain longitudinal patient medical history** for comprehensive care
- **Provide multilingual patient explanations** for better health literacy
- **Enable assistive clinical decision support** (non-diagnostic)

---

## 🏗️ Architecture Layers

### 1. 👥 User Layer (Blue Background)

**Components:**
- **Doctors** - Access via web dashboard to upload notes/voice and view summaries
- **Patients** - View simplified health summaries and explanations
- **Hospital EHR** - Integration with existing hospital systems

**Purpose:** Entry points for all system users

---

### 2. 🔐 API & Access Layer (Orange Background)

**Components:**
- **CloudFront CDN** - Global content delivery for web dashboard
- **API Gateway** - Secure REST APIs for all client interactions
- **Cognito** - User authentication with MFA support

**Purpose:** Secure access control and API management

**Security Features:**
- Multi-factor authentication (MFA)
- Token-based authorization
- Rate limiting and throttling

---

### 3. ⚙️ Application Layer - Microservices (Purple Background)

**Components:**
- **Workflow Orchestrator** - Main Lambda function coordinating all services
- **Summarization Service** - Handles clinical note summarization
- **History Service** - Manages patient timeline and history
- **Translation Service** - Handles multilingual output generation
- **Alert Service** - Triggers allergy and chronic condition alerts

**Purpose:** Business logic and service orchestration

**Design Pattern:** Microservices architecture for scalability and maintainability

---

### 4. 🤖 AI/ML Processing Layer (Green Background)

**Components:**

#### Voice & Text Processing:
- **Amazon Transcribe** - Converts voice input to text (optional)
- **Amazon Comprehend Medical** - Extracts medical entities:
  - Conditions (diagnoses)
  - Medications (drug names)
  - Dosage (quantities and frequencies)
  - Symptoms (patient complaints)

#### LLM & Intelligence:
- **Amazon Bedrock (Claude 3.5)** - Generates:
  - Structured clinical summaries (SOAP format)
  - Patient-friendly explanations
  - Discharge summaries
- **Amazon Translate** - Multilingual output (Hindi, Tamil, Telugu, etc.)

#### Model Fine-tuning:
- **Amazon SageMaker** - Fine-tune models on synthetic datasets (optional)

**Purpose:** AI-powered clinical intelligence and natural language processing

---

### 5. 💾 Data Storage Layer (Pink Background)

**Components:**

#### Document Storage:
- **S3 - Clinical Summaries** - Encrypted structured summaries
- **S3 - Raw Notes & Outputs** - Original documents and AI outputs

#### Patient History Database:
- **DynamoDB - Patient Timeline**
  - Partition Key: PatientID
  - Sort Key: Timestamp
  - Stores chronological visit data
- **DynamoDB - Patient Metadata & Snapshots**
  - Partition Key: PatientID
  - Stores aggregated patient snapshots

#### Relational Data:
- **RDS** - Optional relational medical records (for complex queries)

**Purpose:** Persistent storage with encryption at rest

**Encryption:** All data encrypted using AWS KMS

---

### 6. 📊 Longitudinal Patient History (Yellow Background - Key Differentiator)

**Components:**
- **Timeline Builder** - Constructs chronological patient journey
- **Snapshot Generator** - Creates real-time patient summary
- **Alert Logic** - Triggers alerts for allergies and chronic conditions

**Patient Snapshot Components:**
- Active Medications
- Chronic Conditions
- Recent Vitals
- Allergies
- Visit History
- Risk Alerts

**Purpose:** Comprehensive patient view for informed clinical decisions

**Key Differentiator:** This is what sets SwasthyaAI apart from basic summarization tools

---

### 7. 🔒 Security & Compliance Layer (Red Background)

**Components:**
- **IAM** - Role-based access control (RBAC)
- **KMS** - Encryption key management
- **CloudWatch** - Audit logs and monitoring

**Purpose:** Security, compliance, and observability

**Compliance Features:**
- No PHI used (synthetic/public datasets only)
- Audit logs enabled for all operations
- Encryption at rest and in transit
- Role-based access control

---

## 🔄 Complete Data Flow (Numbered Steps)

### Step 1-3: Input Processing
1. **Doctor uploads notes or voice** → CloudFront → API Gateway
2. **Voice input** → Transcribe (converts to text)
3. **Text output** → Comprehend Medical

### Step 4-6: AI Processing
4. **Comprehend extracts entities:**
   - Conditions
   - Medications
   - Dosage
   - Symptoms
5. **Bedrock generates structured summary** (SOAP format)
6. **Translate creates multilingual output**

### Step 7-9: Data Storage
7. **Summarization Service stores summary** → S3
8. **History Service updates timeline** → DynamoDB
9. **Timeline Builder adds visit data** → Patient Timeline

### Step 10-11: Patient History
10. **Timeline Builder constructs patient journey**
11. **Snapshot Generator creates aggregated view** → Patient Metadata

### Step 12-14: Dashboard Display
12. **History Service retrieves snapshot** from DynamoDB
13. **API Gateway prepares response:**
    - Clinical Summary
    - Patient Explanation
    - Longitudinal Snapshot
14. **Dashboard displays** to doctor

---

## 🎨 Color-Coded Flows

- **Blue** - User interactions and dashboard display
- **Green** - AI processing and successful operations
- **Orange** - Entity extraction and data enrichment
- **Brown** - Patient history and timeline operations
- **Red** - Alerts and security operations
- **Purple** - Translation and multilingual flows
- **Gray (dashed)** - Optional flows and raw data storage

---

## 🔐 Security Highlights

### Encryption
- **At Rest:** All S3 buckets and DynamoDB tables encrypted with KMS
- **In Transit:** TLS 1.3 for all API communications

### Access Control
- **IAM Roles:** Least privilege access for all Lambda functions
- **Cognito:** MFA-enabled authentication for doctors
- **API Gateway:** Token-based authorization

### Monitoring
- **CloudWatch:** Real-time logs and metrics
- **Audit Logs:** All API calls and data access logged
- **Alerts:** Automated alerts for security events

---

## 📊 Key Features Highlighted in Diagram

### 1. Microservices Architecture
- Separate Lambda functions for each service
- Independent scaling and deployment
- Clear separation of concerns

### 2. Longitudinal Patient History (Key Differentiator)
- **Highlighted with bold yellow border**
- Timeline builder for chronological view
- Snapshot generator for quick patient overview
- Alert logic for critical conditions

### 3. AI/ML Pipeline
- Voice → Text → Entity Extraction → Summarization → Translation
- Human-readable explanations for patients
- Structured data for clinical use

### 4. Security Boundaries
- Dotted lines show encryption and authorization
- Clear separation between layers
- Audit logging throughout

### 5. Data Flow Clarity
- Numbered steps (1-14) show complete journey
- Color-coded arrows for different flow types
- Bold arrows for critical paths

---

## 🚀 Use Cases

### For Doctors:
1. Upload clinical notes (text or voice)
2. AI generates structured SOAP summary
3. View patient's complete medical history
4. Get alerts for allergies and chronic conditions
5. Access multilingual patient explanations

### For Patients:
1. View simplified health summaries
2. Understand medical conditions in their language
3. Access their complete medical timeline

### For Hospital Administrators:
1. Integrate with existing EHR systems
2. Reduce documentation time for doctors
3. Improve patient care quality
4. Maintain comprehensive medical records

---

## 💡 Technical Highlights

### Scalability
- **Lambda:** Auto-scales to handle variable load
- **DynamoDB:** Scales read/write capacity automatically
- **S3:** Unlimited storage capacity
- **API Gateway:** Handles millions of requests per second

### Performance
- **DynamoDB:** Single-digit millisecond latency
- **Lambda:** Sub-second response times
- **CloudFront:** Edge caching for global users
- **Comprehend Medical:** Real-time entity extraction

### Cost Optimization
- **Serverless:** Pay only for actual usage
- **S3 Lifecycle:** Move old data to cheaper storage tiers
- **DynamoDB On-Demand:** Pay per request for low-traffic tables
- **Lambda:** Optimized memory allocation

---

## 📋 Component Details

### Amazon Comprehend Medical Entities

**Extracted Information:**
- **Conditions:** Diabetes, Hypertension, Asthma, etc.
- **Medications:** Metformin, Lisinopril, Albuterol, etc.
- **Dosage:** 500mg, twice daily, as needed, etc.
- **Symptoms:** Fever, cough, chest pain, etc.
- **Procedures:** X-ray, blood test, ECG, etc.
- **Anatomy:** Heart, lungs, liver, etc.

### Amazon Bedrock Outputs

**Generated Content:**
- **SOAP Notes:**
  - Subjective: Patient complaints
  - Objective: Clinical findings
  - Assessment: Diagnosis
  - Plan: Treatment plan
- **Discharge Summaries:** Complete visit summary
- **Patient Explanations:** Simplified medical information

### DynamoDB Schema

**Patient Timeline Table:**
```
PK: PatientID (e.g., "P12345")
SK: Timestamp (e.g., "2026-02-12T10:30:00Z")
Attributes:
  - VisitID
  - DoctorID
  - Conditions
  - Medications
  - Vitals
  - Summary
```

**Patient Metadata Table:**
```
PK: PatientID (e.g., "P12345")
Attributes:
  - Name
  - Age
  - Gender
  - ActiveMedications
  - ChronicConditions
  - Allergies
  - LastVisit
  - RiskScore
```

---

## 🎓 Architecture Decisions

### Why Serverless?
- **Auto-scaling:** Handle variable patient load
- **Cost-effective:** Pay per use, not per server
- **No maintenance:** Focus on features, not infrastructure
- **High availability:** Built-in redundancy

### Why DynamoDB for Patient History?
- **Fast:** Single-digit millisecond latency
- **Scalable:** Handles millions of records
- **Flexible:** NoSQL schema for evolving data
- **Streams:** Real-time triggers for timeline updates

### Why Bedrock for LLM?
- **Managed:** No infrastructure to manage
- **Secure:** Built-in security and compliance
- **Latest Models:** Access to Claude 3.5 Sonnet
- **Cost-effective:** Pay per token

### Why Microservices?
- **Scalability:** Each service scales independently
- **Maintainability:** Clear separation of concerns
- **Flexibility:** Easy to add new services
- **Resilience:** Failure in one service doesn't affect others

---

## 📈 Scalability Strategy

### Horizontal Scaling
- **Lambda:** 10,000+ concurrent executions
- **API Gateway:** Millions of requests/second
- **DynamoDB:** Automatic capacity scaling
- **S3:** Unlimited storage

### Caching Strategy
- **CloudFront:** Edge caching for static assets
- **API Gateway:** Response caching for read-heavy endpoints
- **DynamoDB:** DAX for microsecond latency (optional)

### Database Optimization
- **Partition Key:** PatientID ensures even distribution
- **Sort Key:** Timestamp enables efficient range queries
- **GSIs:** Additional access patterns (by doctor, by date, etc.)

---

## 🔍 Monitoring & Observability

### CloudWatch Metrics
- Lambda invocation count and duration
- API Gateway request count and latency
- DynamoDB read/write capacity utilization
- Comprehend Medical API calls

### CloudWatch Logs
- Lambda function logs
- API Gateway access logs
- Application logs with structured JSON

### Alarms
- High error rates
- Increased latency
- Capacity threshold breaches
- Security events

---

## 🎯 Hackathon Presentation Tips

### Key Points to Emphasize:
1. **Longitudinal Patient History** - The key differentiator
2. **AI-Powered Summarization** - Reduces doctor burden
3. **Multilingual Support** - Serves diverse Indian population
4. **Secure & Compliant** - HIPAA-ready architecture
5. **Scalable & Cost-Effective** - Serverless design

### Demo Flow:
1. Show doctor uploading clinical notes
2. Demonstrate AI summarization in real-time
3. Display patient timeline with historical data
4. Show patient-friendly explanation in Hindi
5. Highlight allergy alerts and risk factors

### Technical Highlights:
- Official AWS services (no custom infrastructure)
- Microservices architecture
- Real-time processing
- Encrypted storage
- Audit logging

---

## 📞 Questions & Answers

**Q: How is patient data secured?**
A: All data encrypted at rest (KMS) and in transit (TLS 1.3). IAM roles enforce least privilege access. Audit logs track all operations.

**Q: How does longitudinal history work?**
A: Each visit creates a timeline entry in DynamoDB. Timeline Builder aggregates data. Snapshot Generator creates real-time patient summary.

**Q: What if AI makes a mistake?**
A: System is assistive, not diagnostic. Doctors review all AI outputs. Confidence scoring flags uncertain results.

**Q: How does it scale?**
A: Serverless architecture auto-scales. Lambda handles 10,000+ concurrent requests. DynamoDB scales automatically.

**Q: What about cost?**
A: Pay-per-use pricing. Estimated ~$510/month for 1000 patients, 500 visits/month.

---

## ✅ Diagram Checklist

- [x] Layered architecture (User → API → App → AI → Data → Security)
- [x] Clear data flow with numbered steps
- [x] Official AWS icons
- [x] Color-coded flows
- [x] Security boundaries highlighted
- [x] Encryption shown with dotted lines
- [x] Longitudinal patient history emphasized
- [x] Microservices approach visible
- [x] Professional, hackathon-ready design
- [x] All required components included

---

## 🚀 Next Steps

1. **Review Diagram:** Validate with team and stakeholders
2. **Prototype:** Build MVP with core AI pipeline
3. **Test:** Use synthetic medical data
4. **Iterate:** Refine based on feedback
5. **Deploy:** Launch pilot with 1-2 hospitals

---

*SwasthyaAI - AI Powered Clinical Intelligence Platform*  
*Comprehensive Architecture Diagram*  
*Generated: February 12, 2026*
