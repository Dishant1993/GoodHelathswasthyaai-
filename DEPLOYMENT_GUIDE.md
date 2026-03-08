# SwasthyaAI Enhanced - Complete Deployment Guide

## 🎯 Overview

This guide will walk you through deploying the complete SwasthyaAI system with:
- Deep Teal & Warm Cream themed frontend
- Patient Chatbot with floating action button
- Insurance Checker
- Clinical Summarizer (Nova 2 Lite)
- Appointment Booking System
- Complete AWS infrastructure

---

## 📋 Prerequisites

### Required Tools
- AWS CLI v2 configured
- Terraform v1.5+
- Node.js 18+
- Python 3.12+
- npm or yarn

### AWS Account Requirements
- AWS Account with admin access
- Bedrock model access enabled (amazon.nova-2-lite-v1:0)
- Service quotas checked for Lambda, API Gateway, S3

---

## 🚀 Step-by-Step Deployment

### Step 1: Enable Amazon Bedrock Access

1. Go to AWS Console → Amazon Bedrock
2. Navigate to "Model access"
3. Click "Request model access"
4. Select "Amazon Nova 2 Lite" (amazon.nova-2-lite-v1:0)
5. Submit request and wait for approval (usually instant)

### Step 2: Deploy Infrastructure with Terraform

```bash
cd infrastructure

# Initialize Terraform
terraform init

# Review the plan
terraform plan -var-file=environments/dev.tfvars

# Deploy infrastructure
terraform apply -var-file=environments/dev.tfvars

# Note the outputs (API Gateway URL, S3 buckets, etc.)
```

**Expected Resources Created:**
- 5 S3 buckets (conversations, clinical-logs, insurance-policies, insurance-logs, frontend)
- 4 Lambda functions (patient-chatbot, insurance-analyzer, clinical-summarizer-nova, appointment-booking)
- 1 API Gateway with 4 endpoints
- 1 DynamoDB table (Appointments)
- IAM roles and policies
- CloudWatch log groups

### Step 3: Package and Deploy Lambda Functions

#### Python Lambdas

```bash
# Patient Chatbot
cd backend/lambdas/patient_chatbot
pip install -r requirements.txt -t .
zip -r function.zip .
aws lambda update-function-code \
  --function-name swasthyaai-patient-chatbot-dev \
  --zip-file fileb://function.zip

# Insurance Analyzer
cd ../insurance_analyzer
pip install -r requirements.txt -t .
zip -r function.zip .
aws lambda update-function-code \
  --function-name swasthyaai-insurance-analyzer-dev \
  --zip-file fileb://function.zip

# Clinical Summarizer Nova
cd ../clinical_summarizer_nova
pip install -r requirements.txt -t .
zip -r function.zip .
aws lambda update-function-code \
  --function-name swasthyaai-clinical-summarizer-nova-dev \
  --zip-file fileb://function.zip
```

#### Node.js Lambda

```bash
# Appointment Booking
cd backend/lambdas/appointment_booking
npm install
zip -r function.zip .
aws lambda update-function-code \
  --function-name swasthyaai-appointment-booking-dev \
  --zip-file fileb://function.zip
```

### Step 4: Test Lambda Functions

```bash
# Test Patient Chatbot
aws lambda invoke \
  --function-name swasthyaai-patient-chatbot-dev \
  --payload '{"body":"{\"query\":\"What is diabetes?\",\"user_id\":\"test123\"}"}' \
  response.json

cat response.json

# Test Clinical Summarizer
aws lambda invoke \
  --function-name swasthyaai-clinical-summarizer-nova-dev \
  --payload '{"body":"{\"clinical_data\":\"Patient complains of fever and cough for 3 days.\",\"user_id\":\"doc123\"}"}' \
  response.json

cat response.json
```

### Step 5: Configure Frontend Environment

Create `.env` file in `frontend/`:

```bash
cd frontend

cat > .env << EOF
VITE_API_ENDPOINT=https://YOUR_API_ID.execute-api.ap-south-1.amazonaws.com/dev
VITE_AWS_REGION=ap-south-1
VITE_COGNITO_USER_POOL_ID=
VITE_COGNITO_CLIENT_ID=
EOF
```

Replace `YOUR_API_ID` with the actual API Gateway ID from Terraform output.

### Step 6: Build and Deploy Frontend

```bash
cd frontend

# Install dependencies
npm install

# Build for production
npm run build

# Deploy to S3
aws s3 sync dist/ s3://swasthyaai-frontend-dev-YOUR_ACCOUNT_ID/ --delete

# Get the website URL
terraform output frontend_website_endpoint
```

### Step 7: Test the Complete System

1. **Open Frontend**: Navigate to the S3 website endpoint
2. **Login**: Use any email/password (mock auth for now)
3. **Test Chatbot**: Click the floating chat button (bottom right)
4. **Test Insurance**: Navigate to Insurance Checker
5. **Test Clinical Notes**: Go to New Consultation

---

## 🧪 Testing Checklist

### Backend Testing

- [ ] Patient Chatbot responds to queries
- [ ] Insurance Analyzer processes policies
- [ ] Clinical Summarizer generates SOAP notes
- [ ] Appointment Booking creates appointments
- [ ] All Lambda functions log to CloudWatch
- [ ] S3 buckets store data correctly

### Frontend Testing

- [ ] Login page works
- [ ] Dashboard loads
- [ ] Sidebar navigation works
- [ ] Chatbot opens and sends messages
- [ ] Insurance checker accepts input
- [ ] Theme colors are Deep Teal & Warm Cream
- [ ] Responsive design works on mobile

### Integration Testing

- [ ] Frontend calls API Gateway successfully
- [ ] API Gateway invokes Lambda functions
- [ ] Lambda functions call Bedrock
- [ ] Data is saved to S3
- [ ] CORS headers work correctly

---

## 🔒 Security Configuration

### Enable HTTPS (Production)

1. **Get SSL Certificate**:
```bash
aws acm request-certificate \
  --domain-name swasthyaai.yourdomain.com \
  --validation-method DNS \
  --region ap-south-1
```

2. **Create CloudFront Distribution**:
```bash
# Use Terraform or AWS Console to create CloudFront
# Point to S3 bucket
# Use ACM certificate
```

### Enable API Authentication

1. **Create Cognito User Pool** (if not exists)
2. **Update API Gateway** to use Cognito authorizer
3. **Update Frontend** to use Cognito authentication

### Enable Encryption

All resources already have encryption enabled:
- S3: AES-256
- DynamoDB: AWS managed keys
- API Gateway: TLS 1.2+

---

## 📊 Monitoring Setup

### CloudWatch Dashboards

```bash
# Create custom dashboard
aws cloudwatch put-dashboard \
  --dashboard-name SwasthyaAI-Dashboard \
  --dashboard-body file://cloudwatch-dashboard.json
```

### CloudWatch Alarms

```bash
# High error rate alarm
aws cloudwatch put-metric-alarm \
  --alarm-name swasthyaai-high-error-rate \
  --alarm-description "Alert when error rate > 5%" \
  --metric-name Errors \
  --namespace AWS/Lambda \
  --statistic Sum \
  --period 300 \
  --evaluation-periods 2 \
  --threshold 10 \
  --comparison-operator GreaterThanThreshold
```

---

## 💰 Cost Optimization

### Current Monthly Costs (Estimated)

| Service | Usage | Cost |
|---------|-------|------|
| Lambda | 1M requests | $10-15 |
| Bedrock Nova 2 Lite | 100K tokens/day | $30-50 |
| S3 | 10GB storage | $5-10 |
| API Gateway | 1M requests | $3.50 |
| DynamoDB | On-demand | $5-10 |
| Comprehend Medical | 10K calls | $10-20 |
| **Total** | | **$63.50-$108.50** |

### Optimization Tips

1. **Enable Lambda Reserved Concurrency** for predictable workloads
2. **Use S3 Lifecycle Policies** to move old logs to Glacier
3. **Enable API Gateway Caching** for frequently accessed endpoints
4. **Monitor Bedrock Usage** and optimize prompts
5. **Use DynamoDB On-Demand** for variable traffic

---

## 🐛 Troubleshooting

### Common Issues

#### 1. Lambda Function Timeout
**Error**: Task timed out after 30 seconds
**Solution**: Increase timeout in `lambda.tf` or optimize code

#### 2. Bedrock Access Denied
**Error**: User is not authorized to perform: bedrock:InvokeModel
**Solution**: Check IAM role has bedrock policy attached

#### 3. CORS Error in Frontend
**Error**: Access to fetch blocked by CORS policy
**Solution**: Verify API Gateway CORS configuration

#### 4. S3 Bucket Not Found
**Error**: NoSuchBucket
**Solution**: Check bucket names match environment variables

#### 5. DynamoDB Throttling
**Error**: ProvisionedThroughputExceededException
**Solution**: Switch to on-demand billing mode

---

## 📝 API Endpoints

### Base URL
```
https://YOUR_API_ID.execute-api.ap-south-1.amazonaws.com/dev
```

### Endpoints

#### 1. Patient Chatbot
```bash
POST /chat
Content-Type: application/json

{
  "query": "What is diabetes?",
  "user_id": "patient123",
  "history": []
}
```

#### 2. Clinical Summarizer
```bash
POST /clinical/generate
Content-Type: application/json

{
  "clinical_data": "Patient complains of fever...",
  "user_id": "doctor123",
  "patient_id": "patient456"
}
```

#### 3. Insurance Analyzer
```bash
POST /insurance/analyze
Content-Type: application/json

{
  "policy_key": "policies/patient123/policy.pdf",
  "procedure_code": "CPT-99213",
  "provider_network": {"hospital": "Apollo"},
  "patient_id": "patient123"
}
```

#### 4. Appointment Booking
```bash
POST /appointments/book
Content-Type: application/json

{
  "patient_id": "patient123",
  "doctor_id": "doctor456",
  "date": "2024-03-15",
  "time": "10:00",
  "reason": "General consultation"
}
```

---

## 🎉 Success Criteria

Your deployment is successful when:

- ✅ All Lambda functions are deployed and running
- ✅ API Gateway returns 200 responses
- ✅ Frontend loads without errors
- ✅ Chatbot responds to messages
- ✅ Insurance checker analyzes policies
- ✅ Clinical notes are generated in SOAP format
- ✅ Appointments can be booked
- ✅ Data is encrypted at rest and in transit
- ✅ CloudWatch logs show no errors

---

## 📞 Support

For issues or questions:
1. Check CloudWatch logs for errors
2. Review Terraform state for infrastructure issues
3. Test Lambda functions individually
4. Verify IAM permissions
5. Check Bedrock model access

---

## 🔄 Updates and Maintenance

### Updating Lambda Functions
```bash
# Make code changes
# Re-package and deploy
cd backend/lambdas/patient_chatbot
zip -r function.zip .
aws lambda update-function-code \
  --function-name swasthyaai-patient-chatbot-dev \
  --zip-file fileb://function.zip
```

### Updating Frontend
```bash
cd frontend
npm run build
aws s3 sync dist/ s3://swasthyaai-frontend-dev-YOUR_ACCOUNT_ID/ --delete
```

### Updating Infrastructure
```bash
cd infrastructure
terraform plan -var-file=environments/dev.tfvars
terraform apply -var-file=environments/dev.tfvars
```

---

## ✅ Deployment Complete!

Your SwasthyaAI system is now fully deployed with:
- ✨ Beautiful Deep Teal & Warm Cream UI
- 🤖 AI-powered patient chatbot
- 🏥 Clinical documentation with SOAP format
- 💊 Insurance eligibility checker
- 📅 Appointment booking system
- 🔒 HIPAA-ready security
- 📊 Complete monitoring and logging

**Next Steps:**
1. Add real authentication (Cognito)
2. Upload sample insurance policies
3. Create doctor accounts
4. Train staff on the system
5. Start pilot with real patients

Congratulations! 🎊
