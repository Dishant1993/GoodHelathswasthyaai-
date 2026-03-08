# SwasthyaAI - Quick Start Guide

## 🚀 Deploy in 15 Minutes

### Prerequisites
```bash
# Check you have these installed
aws --version        # AWS CLI v2
terraform --version  # Terraform v1.5+
node --version       # Node.js 18+
python --version     # Python 3.12+
```

### Step 1: Enable Bedrock (2 min)
```bash
# Go to AWS Console → Bedrock → Model access
# Enable: amazon.nova-2-lite-v1:0
```

### Step 2: Deploy Infrastructure (5 min)
```bash
cd infrastructure
terraform init
terraform apply -var-file=environments/dev.tfvars -auto-approve

# Save the API Gateway URL from output
export API_URL=$(terraform output -raw api_gateway_url)
```

### Step 3: Deploy Lambda Functions (5 min)
```bash
# Quick deploy script
cd ../backend/lambdas

# Patient Chatbot
cd patient_chatbot && pip install -r requirements.txt -t . && zip -r function.zip . && \
aws lambda update-function-code --function-name swasthyaai-patient-chatbot-dev --zip-file fileb://function.zip

# Insurance Analyzer
cd ../insurance_analyzer && pip install -r requirements.txt -t . && zip -r function.zip . && \
aws lambda update-function-code --function-name swasthyaai-insurance-analyzer-dev --zip-file fileb://function.zip

# Clinical Summarizer
cd ../clinical_summarizer_nova && pip install -r requirements.txt -t . && zip -r function.zip . && \
aws lambda update-function-code --function-name swasthyaai-clinical-summarizer-nova-dev --zip-file fileb://function.zip

# Appointment Booking
cd ../appointment_booking && npm install && zip -r function.zip . && \
aws lambda update-function-code --function-name swasthyaai-appointment-booking-dev --zip-file fileb://function.zip
```

### Step 4: Deploy Frontend (3 min)
```bash
cd ../../frontend

# Create .env file
echo "VITE_API_ENDPOINT=$API_URL" > .env

# Build and deploy
npm install
npm run build

# Get bucket name from Terraform
BUCKET=$(cd ../infrastructure && terraform output -raw s3_buckets | jq -r '.frontend')
aws s3 sync dist/ s3://$BUCKET/ --delete

# Get website URL
cd ../infrastructure
terraform output frontend_website_endpoint
```

### Step 5: Test! (1 min)
```bash
# Open the website URL in your browser
# Login with any email/password
# Click the chat button (bottom right)
# Send a message: "What is diabetes?"
```

## ✅ Success!

Your SwasthyaAI system is now live with:
- ✨ Patient Chatbot
- 🏥 Clinical Documentation
- 💊 Insurance Checker
- 📅 Appointment Booking

---

## 🧪 Quick Tests

### Test Chatbot
```bash
curl -X POST $API_URL/chat \
  -H "Content-Type: application/json" \
  -d '{"query":"What is diabetes?","user_id":"test123"}'
```

### Test Clinical Summarizer
```bash
curl -X POST $API_URL/clinical/generate \
  -H "Content-Type: application/json" \
  -d '{"clinical_data":"Patient has fever and cough","user_id":"doc123"}'
```

### Test Insurance Analyzer
```bash
curl -X POST $API_URL/insurance/analyze \
  -H "Content-Type: application/json" \
  -d '{"policy_key":"test.pdf","procedure_code":"CPT-99213","patient_id":"p123"}'
```

---

## 🐛 Troubleshooting

### Lambda Timeout
```bash
# Increase timeout
aws lambda update-function-configuration \
  --function-name swasthyaai-patient-chatbot-dev \
  --timeout 60
```

### CORS Error
```bash
# Check API Gateway CORS
aws apigateway get-method \
  --rest-api-id YOUR_API_ID \
  --resource-id YOUR_RESOURCE_ID \
  --http-method OPTIONS
```

### Check Logs
```bash
# View Lambda logs
aws logs tail /aws/lambda/swasthyaai-patient-chatbot-dev --follow
```

---

## 📚 Full Documentation

- **Complete Guide**: See `DEPLOYMENT_GUIDE.md`
- **Implementation Details**: See `IMPLEMENTATION_COMPLETE_ENHANCED.md`
- **Requirements**: See `ENHANCED_REQUIREMENTS.md`

---

## 💡 Tips

1. **Save API URL**: Export it to your shell profile
2. **Monitor Costs**: Set up billing alerts
3. **Check Logs**: Use CloudWatch for debugging
4. **Test Locally**: Use `npm run dev` for frontend
5. **Backup**: Enable S3 versioning

---

## 🎉 You're Done!

Visit your website and start using SwasthyaAI!

**Questions?** Check the full documentation or CloudWatch logs.
