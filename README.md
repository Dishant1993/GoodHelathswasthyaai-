# SwasthyaAI - AI-Powered Clinical Intelligence Assistant

SwasthyaAI is a comprehensive healthcare management platform that leverages AWS services and AI to provide clinical intelligence, patient management, and insurance analysis capabilities.

## Features

### For Doctors
- **Dashboard**: View upcoming appointments and patient statistics
- **Clinical Note Editor**: AI-powered SOAP note generation using Amazon Bedrock
- **Patient History**: Access complete patient medical records and timeline
- **Patient Reports**: View and manage patient medical reports
- **Appointment Management**: Manage patient appointments

### For Patients
- **Dashboard**: View upcoming appointments and health summary
- **Book Appointments**: Schedule appointments with doctors
- **My Reports**: Upload and manage personal medical reports
- **Insurance Checker**: AI-powered insurance eligibility verification
- **Patient Chatbot**: Get instant answers to health-related questions

## Technology Stack

### Frontend
- **React** with TypeScript
- **Material-UI (MUI)** for UI components
- **React Router** for navigation
- **Vite** for build tooling
- **Redux** for state management

### Backend
- **AWS Lambda** (Python & Node.js)
- **Amazon Bedrock** (Nova Lite model) for AI capabilities
- **Amazon DynamoDB** for data storage
- **Amazon S3** for file storage
- **Amazon API Gateway** for REST APIs

### Infrastructure
- **Terraform** for Infrastructure as Code
- **AWS CloudWatch** for monitoring and logging

## Architecture

```
Frontend (React) → API Gateway → Lambda Functions → Bedrock/DynamoDB/S3
```

### Key Components
1. **Authentication Service**: User signup/login with encrypted passwords
2. **Appointment Booking**: Real-time appointment scheduling
3. **Clinical Summarizer**: AI-powered SOAP note generation
4. **Insurance Analyzer**: Policy coverage analysis using AI
5. **Patient Chatbot**: Conversational AI for patient queries
6. **Patient History**: Comprehensive medical record management

## Prerequisites

- **Node.js** (v18 or higher)
- **Python** (v3.12)
- **AWS CLI** configured with appropriate credentials
- **Terraform** (v1.0 or higher)
- **AWS Account** with access to:
  - Lambda
  - DynamoDB
  - S3
  - API Gateway
  - Bedrock (Nova Lite model access)

## Installation

### 1. Clone the Repository

```bash
git clone https://github.com/YOUR_USERNAME/swasthyaai.git
cd swasthyaai
```

### 2. Frontend Setup

```bash
cd frontend
npm install
```

Create a `.env` file in the `frontend` directory:

```env
VITE_API_ENDPOINT=https://YOUR_API_GATEWAY_URL/dev
VITE_COGNITO_USER_POOL_ID=your_user_pool_id
VITE_COGNITO_CLIENT_ID=your_client_id
```

### 3. Backend Setup

Install dependencies for each Lambda function:

```bash
# For Python Lambdas
cd backend/lambdas/auth
pip install -r requirements.txt -t .

cd ../insurance_analyzer
pip install -r requirements.txt -t .

# Repeat for other Python Lambda functions
```

```bash
# For Node.js Lambdas
cd backend/lambdas/appointment_booking
npm install
```

### 4. Infrastructure Deployment

```bash
cd infrastructure
terraform init
terraform plan
terraform apply
```

## Configuration

### AWS Region
The application is configured for `us-east-1`. To change the region, update:
- `infrastructure/variables.tf`
- Lambda environment variables
- Frontend API endpoint

### Bedrock Model
The application uses `us.amazon.nova-lite-v1:0`. Ensure you have access to this model in your AWS account.

## Deployment

### Deploy Infrastructure

```bash
cd infrastructure
terraform apply
```

### Deploy Lambda Functions

```bash
# Package and deploy each Lambda
cd backend/lambdas/auth
zip -r function.zip .
aws lambda update-function-code --function-name swasthyaai-auth-dev --zip-file fileb://function.zip
```

Or use the deployment script:

```bash
./deploy-lambdas.ps1
```

### Deploy Frontend

```bash
cd frontend
npm run build
aws s3 sync dist/ s3://YOUR_FRONTEND_BUCKET --delete
```

## Usage

### For Doctors

1. **Sign Up**: Create an account with role "Doctor"
2. **Login**: Access the doctor dashboard
3. **Manage Patients**: View patient history and reports
4. **Create Notes**: Generate AI-powered clinical notes
5. **Manage Appointments**: View and manage patient appointments

### For Patients

1. **Sign Up**: Create an account with role "Patient"
2. **Login**: Access the patient dashboard
3. **Book Appointments**: Schedule appointments with doctors
4. **Upload Reports**: Manage personal medical reports
5. **Check Insurance**: Verify insurance coverage for procedures
6. **Chat**: Get instant answers from the AI chatbot

## API Endpoints

### Authentication
- `POST /auth/signup` - User registration
- `POST /auth/login` - User login
- `GET /auth/profile` - Get user profile
- `PUT /auth/profile` - Update user profile
- `GET /auth/doctors` - List all doctors
- `GET /auth/patients` - List all patients

### Appointments
- `POST /appointments/book` - Book an appointment
- `GET /appointments/patient?patient_id={id}` - Get patient appointments
- `GET /appointments/doctor?doctor_id={id}` - Get doctor appointments

### Insurance
- `POST /insurance/analyze` - Analyze insurance coverage

### Clinical
- `POST /clinical/generate` - Generate SOAP notes

### Chat
- `POST /chat` - Send message to chatbot

## Environment Variables

### Lambda Functions

```
REGION=us-east-1
USERS_TABLE=swasthyaai-dev-users
APPOINTMENTS_TABLE=SwasthyaAI-Appointments
INSURANCE_TABLE=swasthyaai-dev-insurance-checks
TIMELINE_TABLE=swasthyaai-dev-timeline
POLICIES_BUCKET=swasthyaai-insurance-policies-dev-{account_id}
LOGS_BUCKET=swasthyaai-insurance-logs-dev-{account_id}
```

## Security

- Passwords are encrypted using bcrypt
- API Gateway with CORS enabled
- S3 buckets with encryption enabled
- DynamoDB with encryption at rest
- IAM roles with least privilege access

## Monitoring

- CloudWatch Logs for Lambda functions
- CloudWatch Metrics for API Gateway
- DynamoDB metrics for database performance

## Troubleshooting

### Common Issues

1. **CORS Errors**: Ensure API Gateway CORS is properly configured
2. **Bedrock Access**: Verify you have access to Nova Lite model
3. **Lambda Timeouts**: Increase timeout in Lambda configuration
4. **DynamoDB Errors**: Check table names and indexes

### Logs

View Lambda logs:
```bash
aws logs tail /aws/lambda/FUNCTION_NAME --follow
```

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License.

## Contact

For questions or support, please open an issue in the GitHub repository.

## Acknowledgments

- AWS Bedrock for AI capabilities
- Material-UI for UI components
- React community for excellent tools and libraries
