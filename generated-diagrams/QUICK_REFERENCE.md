# SwasthyaAI Architecture - Quick Reference Card

## 📊 Diagram File
`swasthyaai_comprehensive_architecture.png`

---

## 🎯 System Purpose
Reduce doctor documentation burden + Maintain longitudinal patient medical history

---

## 🏗️ 7 Architecture Layers

| Layer | Color | Key Components |
|-------|-------|----------------|
| **👥 User** | Blue | Doctors, Patients, Hospital EHR |
| **🔐 API & Access** | Orange | CloudFront, API Gateway, Cognito |
| **⚙️ Application** | Purple | Orchestrator, Microservices (4) |
| **🤖 AI/ML** | Green | Transcribe, Comprehend, Bedrock, Translate, SageMaker |
| **💾 Data Storage** | Pink | S3 (2), DynamoDB (2), RDS |
| **📊 Patient History** | Yellow | Timeline Builder, Snapshot Generator, Alerts |
| **🔒 Security** | Red | IAM, KMS, CloudWatch |

---

## 🔄 Data Flow (14 Steps)

### Input → Processing (Steps 1-6)
1. Doctor uploads notes/voice
2. Transcribe (if voice) → text
3. Comprehend extracts entities
4. Entities → Bedrock
5. Bedrock generates summary
6. Translate → multilingual

### Storage → History (Steps 7-11)
7. Store summary in S3
8. Update timeline in DynamoDB
9. Add visit data
10. Build patient timeline
11. Generate snapshot

### Retrieval → Display (Steps 12-14)
12. Retrieve snapshot
13. Prepare dashboard data
14. Display to doctor

---

## 🎨 Color-Coded Flows

- 🔵 **Blue** - User interactions
- 🟢 **Green** - AI processing
- 🟠 **Orange** - Entity extraction
- 🟤 **Brown** - Patient history
- 🔴 **Red** - Alerts & security
- 🟣 **Purple** - Translation
- ⚪ **Gray (dashed)** - Optional flows

---

## 🔑 Key Differentiator

### 📊 Longitudinal Patient History
- **Timeline Builder** - Chronological patient journey
- **Snapshot Generator** - Real-time patient summary
- **Alert Logic** - Allergy & chronic condition alerts

**Snapshot Includes:**
- Active Medications
- Chronic Conditions
- Recent Vitals
- Allergies
- Visit History
- Risk Alerts

---

## 🤖 AI/ML Components

| Service | Purpose | Output |
|---------|---------|--------|
| **Transcribe** | Voice → Text | Clinical notes text |
| **Comprehend Medical** | Entity Extraction | Conditions, Medications, Dosage, Symptoms |
| **Bedrock (Claude)** | Summarization | SOAP notes, Patient explanations |
| **Translate** | Multilingual | Hindi, Tamil, Telugu, etc. |
| **SageMaker** | Fine-tuning | Custom models (optional) |

---

## 💾 Data Storage

### S3 Buckets
- **Clinical Summaries** - Structured, encrypted
- **Raw Notes** - Original documents

### DynamoDB Tables
- **Patient Timeline** - PK: PatientID, SK: Timestamp
- **Patient Metadata** - PK: PatientID (snapshots)

### RDS (Optional)
- Relational medical records

---

## 🔐 Security Features

### Encryption
- ✅ At Rest: KMS encryption
- ✅ In Transit: TLS 1.3

### Access Control
- ✅ IAM: Role-based access
- ✅ Cognito: MFA authentication
- ✅ API Gateway: Token authorization

### Monitoring
- ✅ CloudWatch: Logs & metrics
- ✅ Audit logs: All operations tracked

---

## ⚙️ Microservices

1. **Workflow Orchestrator** - Main coordinator
2. **Summarization Service** - Clinical summaries
3. **History Service** - Patient timeline
4. **Translation Service** - Multilingual output
5. **Alert Service** - Allergy/condition alerts

---

## 📈 Scalability

- **Lambda:** 10,000+ concurrent executions
- **API Gateway:** Millions of requests/second
- **DynamoDB:** Auto-scaling capacity
- **S3:** Unlimited storage

---

## 💰 Cost Estimate

**~$510/month** for:
- 1000 patients
- 500 visits/month
- 50 doctors

---

## 🎯 Use Cases

### Doctors
- Upload notes (text/voice)
- View AI-generated summaries
- Access patient history
- Get allergy alerts

### Patients
- View health summaries
- Understand conditions (multilingual)
- Access medical timeline

### Hospitals
- EHR integration
- Reduce documentation time
- Improve care quality

---

## 🚀 Key Benefits

1. **Reduces Documentation Burden** - AI summarization
2. **Comprehensive Patient View** - Longitudinal history
3. **Multilingual Support** - Serves diverse population
4. **Secure & Compliant** - HIPAA-ready
5. **Scalable & Cost-Effective** - Serverless architecture

---

## 📋 Hackathon Talking Points

### Problem
- Doctors spend 50% of time on documentation
- Fragmented patient medical history
- Language barriers in patient communication

### Solution
- AI-powered clinical summarization
- Longitudinal patient timeline
- Multilingual patient explanations

### Technology
- AWS serverless architecture
- Amazon Bedrock (Claude 3.5)
- Amazon Comprehend Medical
- Microservices design

### Differentiator
- **Longitudinal Patient History** with real-time snapshots
- Not just summarization, but comprehensive patient intelligence

---

## 🔍 Demo Flow

1. **Upload** - Doctor uploads clinical notes
2. **Process** - AI extracts entities and summarizes
3. **Store** - Data added to patient timeline
4. **Display** - Dashboard shows:
   - Clinical summary (SOAP)
   - Patient explanation (Hindi)
   - Longitudinal snapshot
   - Allergy alerts

---

## ✅ Architecture Checklist

- [x] Layered design
- [x] Official AWS icons
- [x] Clear data flows
- [x] Security boundaries
- [x] Encryption highlighted
- [x] Microservices approach
- [x] Patient history emphasized
- [x] Color-coded flows
- [x] Professional quality
- [x] Hackathon-ready

---

## 📞 Quick Q&A

**Q: Is it HIPAA compliant?**  
A: Architecture is HIPAA-ready. Uses synthetic data for prototype.

**Q: How fast is it?**  
A: < 30 seconds for AI summarization, < 100ms for patient snapshot.

**Q: Can it scale?**  
A: Yes, serverless architecture auto-scales to handle any load.

**Q: What languages?**  
A: Hindi, Tamil, Telugu, Bengali, Marathi, and more via Amazon Translate.

**Q: Is AI diagnostic?**  
A: No, assistive only. Doctors review all AI outputs.

---

## 📁 Related Files

- `swasthyaai_comprehensive_architecture.png` - Main diagram
- `COMPREHENSIVE_DIAGRAM_GUIDE.md` - Detailed guide
- `README.md` - All diagrams documentation

---

*SwasthyaAI - Quick Reference*  
*Print this for presentations!*  
*February 12, 2026*
