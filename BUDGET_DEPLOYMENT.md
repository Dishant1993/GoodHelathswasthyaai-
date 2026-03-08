# SwasthyaAI - Budget Deployment ($90 Credits)

## 💰 Cost-Optimized Deployment Plan

**Budget**: $90 AWS Credits  
**Estimated Monthly Cost**: $15-25 (leaves $65-75 for 3+ months)  
**Strategy**: Minimal infrastructure, free tier maximization

---

## 📊 Cost Breakdown (Optimized)

| Service | Configuration | Monthly Cost | Free Tier |
|---------|--------------|--------------|-----------|
| Lambda | 100K requests | $0.20 | ✅ 1M free |
| Bedrock Nova Lite | 10K requests | $5-10 | ❌ Pay per use |
| S3 | 5GB storage | $0.12 | ✅ 5GB free (12 months) |
| API Gateway | 100K requests | $0.35 | ✅ 1M free (12 months) |
| DynamoDB | On-demand | $1-2 | ✅ 25GB free |
| CloudWatch | Basic logs | $0.50 | ✅ 5GB free |
| **TOTAL** | | **$7-13/month** | **Mostly free tier** |

**Savings**: ~$50-95/month vs full deployment!

---

## 🎯 Minimal Deployment Strategy

### What to Deploy (Essential Only)
✅ **Deploy These**:
1. Patient Chatbot Lambda (most important)
2. Clinical Summarizer Lambda (core feature)
3. API Gateway (2 endpoints only)
4. 2 S3 Buckets (conversations + clinical logs)
5. Frontend hosting (S3 static website)

❌ **Skip These** (Save $40-50/month):
1. ~~Insurance Analyzer~~ (can add later)
2. ~~Appointment Booking~~ (can add later)
3. ~~DynamoDB~~ (not needed for MVP)
4. ~~Comprehend Medical~~ (expensive, use Bedrock only)
5. ~~Multiple environments~~ (dev only)
6. ~~CloudWatch detailed monitoring~~
7. ~~VPC, NAT Gateway~~ (not needed)

---

## 🚀 Step-by-Step Budget Deployment

### Prerequisites (Free)
```bash
# Install AWS CLI (free)
# Configure with your credentials
aws configure
```

### Step 1: Enable Bedrock (Free, but usage costs)
1. Go to AWS Console → Bedrock → Model access
2. Enable **amazon.nova-2-lite-v1:0** only
3. ✅ This is FREE to enable, you only pay per use

### Step 2: Create Minimal S3 Buckets ($0.12/month)

```bash
# Set your AWS account ID
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

# Create conversations bucket
aws s3 mb s3://swasthyaai-conversations-${ACCOUNT_ID} --region ap-south-1

# Create clinical logs bucket
aws s3 mb s3://swasthyaai-clinical-logs-${ACCOUNT_ID} --region ap-south-1

# Create frontend bucket
aws s3 mb s3://swasthyaai-frontend-${ACCOUNT_ID} --region ap-south-1

# Enable encryption (free)
aws s3api put-bucket-encryption \
  --bucket swasthyaai-conversations-${ACCOUNT_ID} \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }'

aws s3api put-bucket-encryption \
  --bucket swasthyaai-clinical-logs-${ACCOUNT_ID} \
  --server-side-encryption-configuration '{
    "Rules": [{
      "ApplyServerSideEncryptionByDefault": {
        "SSEAlgorithm": "AES256"
      }
    }]
  }'

# Configure frontend bucket for website hosting
aws s3 website s3://swasthyaai-frontend-${ACCOUNT_ID}/ \
  --index-document index.html \
  --error-document index.html

# Make frontend bucket public
aws s3api put-bucket-policy \
  --bucket swasthyaai-frontend-${ACCOUNT_ID} \
  --policy '{
    "Version": "2012-10-17",
    "Statement": [{
      "Sid": "PublicReadGetObject",
      "Effect": "Allow",
      "Principal": "*",
      "Action": "s3:GetObject",
      "Resource": "arn:aws:s3:::swasthyaai-frontend-'${ACCOUNT_ID}'/*"
    }]
  }'
```

### Step 3: Create IAM Role for Lambda ($0)

```bash
# Create trust policy
cat > trust-policy.json << 'EOF'
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": {"Service": "lambda.amazonaws.com"},
    "Action": "sts:AssumeRole"
  }]
}
EOF

# Create role
aws iam create-role \
  --role-name SwasthyaAI-Lambda-Role \
  --assume-role-policy-document file://trust-policy.json

# Attach basic execution policy (free)
aws iam attach-role-policy \
  --role-name SwasthyaAI-Lambda-Role \
  --policy-arn arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole

# Create custom policy for S3 and Bedrock
cat > lambda-policy.json << 'EOF'
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["s3:PutObject", "s3:GetObject"],
      "Resource": "arn:aws:s3:::swasthyaai-*/*"
    },
    {
      "Effect": "Allow",
      "Action": "bedrock:InvokeModel",
      "Resource": "arn:aws:bedrock:ap-south-1::foundation-model/amazon.nova-2-lite-v1:0"
    }
  ]
}
EOF

aws iam put-role-policy \
  --role-name SwasthyaAI-Lambda-Role \
  --policy-name SwasthyaAI-Services-Policy \
  --policy-document file://lambda-policy.json

# Get role ARN (save this)
ROLE_ARN=$(aws iam get-role --role-name SwasthyaAI-Lambda-Role --query 'Role.Arn' --output text)
echo "Role ARN: $ROLE_ARN"
```

### Step 4: Deploy Patient Chatbot Lambda ($0.20/month)

```bash
cd backend/lambdas/patient_chatbot

# Install dependencies
pip install boto3 -t .

# Create deployment package
zip -r function.zip .

# Create Lambda function
aws lambda create-function \
  --function-name swasthyaai-chatbot \
  --runtime python3.12 \
  --role $ROLE_ARN \
  --handler handler.lambda_handler \
  --zip-file fileb://function.zip \
  --timeout 30 \
  --memory-size 256 \
  --environment Variables="{
    AWS_REGION=ap-south-1,
    CONVERSATIONS_BUCKET=swasthyaai-conversations-${ACCOUNT_ID}
  }" \
  --region ap-south-1

echo "✅ Patient Chatbot Lambda deployed"
```

### Step 5: Deploy Clinical Summarizer Lambda ($0.20/month)

```bash
cd ../../clinical_summarizer_nova

# Install dependencies
pip install boto3 -t .

# Create deployment package
zip -r function.zip .

# Create Lambda function
aws lambda create-function \
  --function-name swasthyaai-clinical \
  --runtime python3.12 \
  --role $ROLE_ARN \
  --handler handler.lambda_handler \
  --zip-file fileb://function.zip \
  --timeout 30 \
  --memory-size 512 \
  --environment Variables="{
    AWS_REGION=ap-south-1,
    LOGS_BUCKET=swasthyaai-clinical-logs-${ACCOUNT_ID},
    CONFIDENCE_THRESHOLD=0.9
  }" \
  --region ap-south-1

echo "✅ Clinical Summarizer Lambda deployed"
```

### Step 6: Create API Gateway ($0.35/month)

```bash
# Create REST API
API_ID=$(aws apigateway create-rest-api \
  --name SwasthyaAI-API \
  --description "SwasthyaAI Budget API" \
  --region ap-south-1 \
  --query 'id' \
  --output text)

echo "API ID: $API_ID"

# Get root resource ID
ROOT_ID=$(aws apigateway get-resources \
  --rest-api-id $API_ID \
  --query 'items[0].id' \
  --output text)

# Create /chat resource
CHAT_RESOURCE_ID=$(aws apigateway create-resource \
  --rest-api-id $API_ID \
  --parent-id $ROOT_ID \
  --path-part chat \
  --query 'id' \
  --output text)

# Create POST method for /chat
aws apigateway put-method \
  --rest-api-id $API_ID \
  --resource-id $CHAT_RESOURCE_ID \
  --http-method POST \
  --authorization-type NONE

# Get Lambda ARN
CHATBOT_ARN=$(aws lambda get-function \
  --function-name swasthyaai-chatbot \
  --query 'Configuration.FunctionArn' \
  --output text)

# Integrate with Lambda
aws apigateway put-integration \
  --rest-api-id $API_ID \
  --resource-id $CHAT_RESOURCE_ID \
  --http-method POST \
  --type AWS_PROXY \
  --integration-http-method POST \
  --uri "arn:aws:apigateway:ap-south-1:lambda:path/2015-03-31/functions/${CHATBOT_ARN}/invocations"

# Create /clinical resource
CLINICAL_RESOURCE_ID=$(aws apigateway create-resource \
  --rest-api-id $API_ID \
  --parent-id $ROOT_ID \
  --path-part clinical \
  --query 'id' \
  --output text)

# Create POST method for /clinical
aws apigateway put-method \
  --rest-api-id $API_ID \
  --resource-id $CLINICAL_RESOURCE_ID \
  --http-method POST \
  --authorization-type NONE

# Get Clinical Lambda ARN
CLINICAL_ARN=$(aws lambda get-function \
  --function-name swasthyaai-clinical \
  --query 'Configuration.FunctionArn' \
  --output text)

# Integrate with Lambda
aws apigateway put-integration \
  --rest-api-id $API_ID \
  --resource-id $CLINICAL_RESOURCE_ID \
  --http-method POST \
  --type AWS_PROXY \
  --integration-http-method POST \
  --uri "arn:aws:apigateway:ap-south-1:lambda:path/2015-03-31/functions/${CLINICAL_ARN}/invocations"

# Enable CORS for /chat
aws apigateway put-method \
  --rest-api-id $API_ID \
  --resource-id $CHAT_RESOURCE_ID \
  --http-method OPTIONS \
  --authorization-type NONE

aws apigateway put-integration \
  --rest-api-id $API_ID \
  --resource-id $CHAT_RESOURCE_ID \
  --http-method OPTIONS \
  --type MOCK \
  --request-templates '{"application/json": "{\"statusCode\": 200}"}'

aws apigateway put-method-response \
  --rest-api-id $API_ID \
  --resource-id $CHAT_RESOURCE_ID \
  --http-method OPTIONS \
  --status-code 200 \
  --response-parameters '{
    "method.response.header.Access-Control-Allow-Headers": true,
    "method.response.header.Access-Control-Allow-Methods": true,
    "method.response.header.Access-Control-Allow-Origin": true
  }'

aws apigateway put-integration-response \
  --rest-api-id $API_ID \
  --resource-id $CHAT_RESOURCE_ID \
  --http-method OPTIONS \
  --status-code 200 \
  --response-parameters '{
    "method.response.header.Access-Control-Allow-Headers": "'"'"'Content-Type,Authorization'"'"'",
    "method.response.header.Access-Control-Allow-Methods": "'"'"'GET,POST,OPTIONS'"'"'",
    "method.response.header.Access-Control-Allow-Origin": "'"'"'*'"'"'"
  }'

# Grant API Gateway permission to invoke Lambda
aws lambda add-permission \
  --function-name swasthyaai-chatbot \
  --statement-id apigateway-invoke \
  --action lambda:InvokeFunction \
  --principal apigateway.amazonaws.com \
  --source-arn "arn:aws:execute-api:ap-south-1:${ACCOUNT_ID}:${API_ID}/*/*"

aws lambda add-permission \
  --function-name swasthyaai-clinical \
  --statement-id apigateway-invoke \
  --action lambda:InvokeFunction \
  --principal apigateway.amazonaws.com \
  --source-arn "arn:aws:execute-api:ap-south-1:${ACCOUNT_ID}:${API_ID}/*/*"

# Deploy API
aws apigateway create-deployment \
  --rest-api-id $API_ID \
  --stage-name prod

# Get API URL
API_URL="https://${API_ID}.execute-api.ap-south-1.amazonaws.com/prod"
echo "✅ API Gateway deployed"
echo "API URL: $API_URL"
```

### Step 7: Deploy Frontend ($0.12/month)

```bash
cd ../../../../frontend

# Create .env file with API URL
cat > .env << EOF
VITE_API_ENDPOINT=$API_URL
VITE_AWS_REGION=ap-south-1
EOF

# Build frontend
npm install
npm run build

# Deploy to S3
aws s3 sync dist/ s3://swasthyaai-frontend-${ACCOUNT_ID}/ --delete

# Get website URL
WEBSITE_URL="http://swasthyaai-frontend-${ACCOUNT_ID}.s3-website.ap-south-1.amazonaws.com"
echo "✅ Frontend deployed"
echo "Website URL: $WEBSITE_URL"
```

---

## 🧪 Test Your Deployment

### Test 1: Patient Chatbot
```bash
curl -X POST $API_URL/chat \
  -H "Content-Type: application/json" \
  -d '{"query":"What is diabetes?","user_id":"test123"}'
```

### Test 2: Clinical Summarizer
```bash
curl -X POST $API_URL/clinical \
  -H "Content-Type: application/json" \
  -d '{"clinical_data":"Patient has fever and cough for 3 days","user_id":"doc123"}'
```

### Test 3: Frontend
Open your browser and go to: `$WEBSITE_URL`

---

## 💰 Cost Monitoring

### Set Up Billing Alert (FREE)
```bash
# Create SNS topic for alerts
aws sns create-topic --name billing-alerts

# Subscribe your email
aws sns subscribe \
  --topic-arn arn:aws:sns:us-east-1:${ACCOUNT_ID}:billing-alerts \
  --protocol email \
  --notification-endpoint your-email@example.com

# Create billing alarm (must be in us-east-1)
aws cloudwatch put-metric-alarm \
  --alarm-name budget-alert-$20 \
  --alarm-description "Alert when charges exceed $20" \
  --metric-name EstimatedCharges \
  --namespace AWS/Billing \
  --statistic Maximum \
  --period 21600 \
  --evaluation-periods 1 \
  --threshold 20 \
  --comparison-operator GreaterThanThreshold \
  --region us-east-1
```

### Check Current Costs
```bash
# View current month costs
aws ce get-cost-and-usage \
  --time-period Start=$(date -d "$(date +%Y-%m-01)" +%Y-%m-%d),End=$(date +%Y-%m-%d) \
  --granularity MONTHLY \
  --metrics BlendedCost \
  --region us-east-1
```

---

## 🎯 Usage Limits to Stay Under Budget

### Recommended Limits (Per Month)
- **Bedrock Requests**: < 10,000 (Cost: ~$5-10)
- **Lambda Invocations**: < 100,000 (FREE tier)
- **API Gateway Requests**: < 100,000 (FREE tier)
- **S3 Storage**: < 5GB (FREE tier)

### How to Control Costs

1. **Limit Bedrock Usage**:
```python
# Add to Lambda functions
import os
request_count = 0
MAX_REQUESTS = 10000

if request_count >= MAX_REQUESTS:
    return {"error": "Monthly quota exceeded"}
```

2. **Use Shorter Responses**:
```python
# Reduce max_tokens to save money
'max_tokens': 500  # Instead of 2000
```

3. **Cache Responses**:
```python
# Cache common queries in S3
# Check cache before calling Bedrock
```

---

## 📊 Expected Monthly Costs

### Month 1 (Setup + Testing)
- Lambda: $0.20
- Bedrock: $8-12 (10K requests)
- S3: $0.12
- API Gateway: $0.35
- **Total: $8.67-12.67**

### Month 2-3 (Light Usage)
- Lambda: $0.20
- Bedrock: $5-8 (5K requests)
- S3: $0.15
- API Gateway: $0.35
- **Total: $5.70-8.70**

### Your $90 Credits Will Last
- **Pessimistic**: 7-8 months
- **Realistic**: 10-12 months
- **Optimistic**: 15+ months

---

## 🚨 Cost-Saving Tips

### 1. Use Free Tier Maximally
- Stay under 1M Lambda requests/month
- Stay under 1M API Gateway requests/month
- Stay under 5GB S3 storage

### 2. Optimize Bedrock Usage
- Cache common responses
- Use shorter prompts
- Reduce max_tokens
- Implement rate limiting

### 3. Delete Unused Resources
```bash
# Delete old logs
aws s3 rm s3://swasthyaai-conversations-${ACCOUNT_ID}/ --recursive --exclude "*" --include "*/2024-01-*"
```

### 4. Monitor Daily
```bash
# Check costs daily
aws ce get-cost-and-usage \
  --time-period Start=$(date -d "yesterday" +%Y-%m-%d),End=$(date +%Y-%m-%d) \
  --granularity DAILY \
  --metrics BlendedCost
```

---

## 🎉 Success Checklist

After deployment, verify:
- [ ] Patient chatbot responds to queries
- [ ] Clinical summarizer generates SOAP notes
- [ ] Frontend loads at website URL
- [ ] API Gateway returns 200 responses
- [ ] S3 buckets store logs
- [ ] Billing alert is configured
- [ ] Current costs < $15/month

---

## 🔄 Adding More Features Later

When you have more budget:

### Add Insurance Analyzer (+$5/month)
```bash
# Deploy insurance analyzer Lambda
# Add /insurance endpoint to API Gateway
```

### Add Appointment Booking (+$2/month)
```bash
# Create DynamoDB table
# Deploy appointment Lambda
# Add /appointments endpoint
```

### Add Comprehend Medical (+$10-20/month)
```bash
# Enable Comprehend Medical
# Update Lambda to use it
```

---

## ⚠️ What's NOT Included (To Save Money)

- ❌ Insurance Analyzer (saves $5-10/month)
- ❌ Appointment Booking (saves $2-5/month)
- ❌ DynamoDB (saves $1-2/month)
- ❌ Comprehend Medical (saves $10-20/month)
- ❌ Multiple environments (saves $10-20/month)
- ❌ VPC/NAT Gateway (saves $30-40/month)
- ❌ CloudWatch detailed monitoring (saves $5-10/month)

**Total Savings: $63-107/month!**

---

## 🎯 Deployment Complete!

You now have:
- ✅ Patient AI Chatbot (Nova 2 Lite)
- ✅ Clinical SOAP Note Generator
- ✅ Beautiful Frontend UI
- ✅ API Gateway
- ✅ Secure S3 Storage
- ✅ Cost monitoring

**All for just $8-13/month!**

Your $90 credits will last **7-12 months** with this setup.

---

## 📞 Need Help?

If deployment fails:
1. Check CloudWatch logs
2. Verify IAM permissions
3. Confirm Bedrock access enabled
4. Check API Gateway CORS

**Budget-friendly deployment complete! 🎉**
