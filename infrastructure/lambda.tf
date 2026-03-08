# Lambda Functions for SwasthyaAI

# Lambda Execution Role
resource "aws_iam_role" "lambda_execution_role" {
  name = "${var.project_name}-lambda-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-lambda-role-${var.environment}"
    }
  )
}

# Attach basic Lambda execution policy
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# Lambda policy for S3, DynamoDB, Comprehend Medical
resource "aws_iam_policy" "lambda_services_policy" {
  name        = "${var.project_name}-lambda-services-policy-${var.environment}"
  description = "Policy for Lambda to access S3, DynamoDB, and Comprehend Medical"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject",
          "s3:DeleteObject"
        ]
        Resource = [
          "${aws_s3_bucket.conversations.arn}/*",
          "${aws_s3_bucket.clinical_logs.arn}/*",
          "${aws_s3_bucket.insurance_policies.arn}/*",
          "${aws_s3_bucket.insurance_logs.arn}/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "dynamodb:GetItem",
          "dynamodb:PutItem",
          "dynamodb:Query",
          "dynamodb:Scan",
          "dynamodb:UpdateItem"
        ]
        Resource = [
          aws_dynamodb_table.appointments.arn,
          "${aws_dynamodb_table.appointments.arn}/index/*",
          aws_dynamodb_table.users.arn,
          "${aws_dynamodb_table.users.arn}/index/*",
          aws_dynamodb_table.clinical_notes.arn,
          "${aws_dynamodb_table.clinical_notes.arn}/index/*",
          aws_dynamodb_table.timeline.arn,
          "${aws_dynamodb_table.timeline.arn}/index/*",
          aws_dynamodb_table.insurance_checks.arn,
          "${aws_dynamodb_table.insurance_checks.arn}/index/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "comprehendmedical:DetectEntitiesV2",
          "comprehendmedical:InferICD10CM",
          "comprehendmedical:InferRxNorm"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "bedrock:InvokeModel",
          "bedrock:InvokeModelWithResponseStream"
        ]
        Resource = [
          "arn:aws:bedrock:*::foundation-model/*",
          "arn:aws:bedrock:*:*:inference-profile/*"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt",
          "kms:Encrypt",
          "kms:GenerateDataKey",
          "kms:DescribeKey"
        ]
        Resource = "*"
      }
    ]
  })

  tags = var.common_tags
}

resource "aws_iam_role_policy_attachment" "lambda_services_policy" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = aws_iam_policy.lambda_services_policy.arn
}

# 1. Patient Chatbot Lambda
resource "aws_lambda_function" "patient_chatbot" {
  filename      = "${path.module}/../backend/lambdas/patient_chatbot/function.zip"
  function_name = "${var.project_name}-patient-chatbot-${var.environment}"
  role          = aws_iam_role.lambda_execution_role.arn
  handler       = "handler.lambda_handler"
  runtime       = "python3.12"
  timeout       = 30
  memory_size   = 512

  environment {
    variables = {
      REGION               = var.aws_region
      CONVERSATIONS_BUCKET = aws_s3_bucket.conversations.id
    }
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-patient-chatbot-${var.environment}"
    }
  )
}

# 2. Insurance Analyzer Lambda
resource "aws_lambda_function" "insurance_analyzer" {
  filename      = "${path.module}/../backend/lambdas/insurance_analyzer/function.zip"
  function_name = "${var.project_name}-insurance-analyzer-${var.environment}"
  role          = aws_iam_role.lambda_execution_role.arn
  handler       = "handler.lambda_handler"
  runtime       = "python3.12"
  timeout       = 60
  memory_size   = 1024

  environment {
    variables = {
      REGION           = var.aws_region
      POLICIES_BUCKET  = aws_s3_bucket.insurance_policies.id
      LOGS_BUCKET      = aws_s3_bucket.insurance_logs.id
      INSURANCE_TABLE  = aws_dynamodb_table.insurance_checks.name
      TIMELINE_TABLE   = aws_dynamodb_table.timeline.name
    }
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-insurance-analyzer-${var.environment}"
    }
  )
}

# 3. Clinical Summarizer Nova Lambda
resource "aws_lambda_function" "clinical_summarizer_nova" {
  filename      = "${path.module}/../backend/lambdas/clinical_summarizer_nova/function.zip"
  function_name = "${var.project_name}-clinical-summarizer-nova-${var.environment}"
  role          = aws_iam_role.lambda_execution_role.arn
  handler       = "handler.lambda_handler"
  runtime       = "python3.12"
  timeout       = 30
  memory_size   = 1024

  environment {
    variables = {
      REGION                = var.aws_region
      LOGS_BUCKET           = aws_s3_bucket.clinical_logs.id
      CONFIDENCE_THRESHOLD  = "0.9"
      CLINICAL_NOTES_TABLE  = aws_dynamodb_table.clinical_notes.name
      TIMELINE_TABLE        = aws_dynamodb_table.timeline.name
    }
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-clinical-summarizer-nova-${var.environment}"
    }
  )
}

# 4. Appointment Booking Lambda
resource "aws_lambda_function" "appointment_booking" {
  filename      = "${path.module}/../backend/lambdas/appointment_booking/function.zip"
  function_name = "${var.project_name}-appointment-booking-${var.environment}"
  role          = aws_iam_role.lambda_execution_role.arn
  handler       = "handler.handler"
  runtime       = "nodejs18.x"
  timeout       = 15
  memory_size   = 512

  environment {
    variables = {
      APPOINTMENTS_TABLE  = aws_dynamodb_table.appointments.name
      DOCTORS_TABLE       = "SwasthyaAI-Doctors"
    }
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-appointment-booking-${var.environment}"
    }
  )
}

# CloudWatch Log Groups
resource "aws_cloudwatch_log_group" "patient_chatbot_logs" {
  name              = "/aws/lambda/${aws_lambda_function.patient_chatbot.function_name}"
  retention_in_days = 14
  tags              = var.common_tags
}

resource "aws_cloudwatch_log_group" "insurance_analyzer_logs" {
  name              = "/aws/lambda/${aws_lambda_function.insurance_analyzer.function_name}"
  retention_in_days = 14
  tags              = var.common_tags
}

resource "aws_cloudwatch_log_group" "clinical_summarizer_nova_logs" {
  name              = "/aws/lambda/${aws_lambda_function.clinical_summarizer_nova.function_name}"
  retention_in_days = 14
  tags              = var.common_tags
}

resource "aws_cloudwatch_log_group" "appointment_booking_logs" {
  name              = "/aws/lambda/${aws_lambda_function.appointment_booking.function_name}"
  retention_in_days = 14
  tags              = var.common_tags
}

resource "aws_cloudwatch_log_group" "auth_logs" {
  name              = "/aws/lambda/${aws_lambda_function.auth.function_name}"
  retention_in_days = 14
  tags              = var.common_tags
}

resource "aws_cloudwatch_log_group" "patient_history_logs" {
  name              = "/aws/lambda/${aws_lambda_function.patient_history.function_name}"
  retention_in_days = 14
  tags              = var.common_tags
}

# Outputs
output "lambda_functions" {
  description = "Lambda function ARNs"
  value = {
    patient_chatbot          = aws_lambda_function.patient_chatbot.arn
    insurance_analyzer       = aws_lambda_function.insurance_analyzer.arn
    clinical_summarizer_nova = aws_lambda_function.clinical_summarizer_nova.arn
    appointment_booking      = aws_lambda_function.appointment_booking.arn
  }
}


# Auth Lambda Function
resource "aws_lambda_function" "auth" {
  filename         = "${path.module}/../backend/lambdas/auth/function.zip"
  function_name    = "${var.project_name}-auth-${var.environment}"
  role            = aws_iam_role.lambda_execution_role.arn
  handler         = "handler.lambda_handler"
  source_code_hash = fileexists("${path.module}/../backend/lambdas/auth/function.zip") ? filebase64sha256("${path.module}/../backend/lambdas/auth/function.zip") : null
  runtime         = "python3.12"
  timeout         = 30
  memory_size     = 512

  environment {
    variables = {
      REGION       = var.aws_region
      USERS_TABLE  = aws_dynamodb_table.users.name
    }
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-auth-${var.environment}"
  })
}

# Patient History Lambda Function
resource "aws_lambda_function" "patient_history" {
  filename         = "${path.module}/../backend/lambdas/patient_history/function.zip"
  function_name    = "${var.project_name}-patient-history-${var.environment}"
  role            = aws_iam_role.lambda_execution_role.arn
  handler         = "handler.lambda_handler"
  source_code_hash = fileexists("${path.module}/../backend/lambdas/patient_history/function.zip") ? filebase64sha256("${path.module}/../backend/lambdas/patient_history/function.zip") : null
  runtime         = "python3.12"
  timeout         = 30
  memory_size     = 512

  environment {
    variables = {
      REGION                = var.aws_region
      CLINICAL_NOTES_TABLE  = aws_dynamodb_table.clinical_notes.name
      APPOINTMENTS_TABLE    = aws_dynamodb_table.appointments.name
      TIMELINE_TABLE        = aws_dynamodb_table.timeline.name
      CLINICAL_LOGS_BUCKET  = aws_s3_bucket.clinical_logs.id
    }
  }

  tags = merge(local.common_tags, {
    Name = "${var.project_name}-patient-history-${var.environment}"
  })
}
