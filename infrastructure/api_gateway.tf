# API Gateway for SwasthyaAI

# CloudWatch Logs role for API Gateway
resource "aws_iam_role" "api_gateway_cloudwatch" {
  name = "${var.project_name}-api-gateway-cloudwatch-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "apigateway.amazonaws.com"
        }
      }
    ]
  })

  tags = var.common_tags
}

resource "aws_iam_role_policy_attachment" "api_gateway_cloudwatch" {
  role       = aws_iam_role.api_gateway_cloudwatch.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
}

resource "aws_api_gateway_account" "main" {
  cloudwatch_role_arn = aws_iam_role.api_gateway_cloudwatch.arn
}

# REST API
resource "aws_api_gateway_rest_api" "swasthyaai_api" {
  name        = "${var.project_name}-api-${var.environment}"
  description = "SwasthyaAI Healthcare API"

  endpoint_configuration {
    types = ["REGIONAL"]
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-api-${var.environment}"
    }
  )
}

# /chat resource
resource "aws_api_gateway_resource" "chat" {
  rest_api_id = aws_api_gateway_rest_api.swasthyaai_api.id
  parent_id   = aws_api_gateway_rest_api.swasthyaai_api.root_resource_id
  path_part   = "chat"
}

resource "aws_api_gateway_method" "chat_post" {
  rest_api_id   = aws_api_gateway_rest_api.swasthyaai_api.id
  resource_id   = aws_api_gateway_resource.chat.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "chat_lambda" {
  rest_api_id = aws_api_gateway_rest_api.swasthyaai_api.id
  resource_id = aws_api_gateway_resource.chat.id
  http_method = aws_api_gateway_method.chat_post.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.patient_chatbot.invoke_arn
}

# CORS for /chat
module "cors_chat" {
  source  = "squidfunk/api-gateway-enable-cors/aws"
  version = "0.3.3"

  api_id          = aws_api_gateway_rest_api.swasthyaai_api.id
  api_resource_id = aws_api_gateway_resource.chat.id
}

# /clinical resource
resource "aws_api_gateway_resource" "clinical" {
  rest_api_id = aws_api_gateway_rest_api.swasthyaai_api.id
  parent_id   = aws_api_gateway_rest_api.swasthyaai_api.root_resource_id
  path_part   = "clinical"
}

resource "aws_api_gateway_resource" "clinical_generate" {
  rest_api_id = aws_api_gateway_rest_api.swasthyaai_api.id
  parent_id   = aws_api_gateway_resource.clinical.id
  path_part   = "generate"
}

resource "aws_api_gateway_method" "clinical_generate_post" {
  rest_api_id   = aws_api_gateway_rest_api.swasthyaai_api.id
  resource_id   = aws_api_gateway_resource.clinical_generate.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "clinical_generate_lambda" {
  rest_api_id = aws_api_gateway_rest_api.swasthyaai_api.id
  resource_id = aws_api_gateway_resource.clinical_generate.id
  http_method = aws_api_gateway_method.clinical_generate_post.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.clinical_summarizer_nova.invoke_arn
}

# /insurance resource
resource "aws_api_gateway_resource" "insurance" {
  rest_api_id = aws_api_gateway_rest_api.swasthyaai_api.id
  parent_id   = aws_api_gateway_rest_api.swasthyaai_api.root_resource_id
  path_part   = "insurance"
}

resource "aws_api_gateway_resource" "insurance_analyze" {
  rest_api_id = aws_api_gateway_rest_api.swasthyaai_api.id
  parent_id   = aws_api_gateway_resource.insurance.id
  path_part   = "analyze"
}

resource "aws_api_gateway_method" "insurance_analyze_post" {
  rest_api_id   = aws_api_gateway_rest_api.swasthyaai_api.id
  resource_id   = aws_api_gateway_resource.insurance_analyze.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "insurance_analyze_lambda" {
  rest_api_id = aws_api_gateway_rest_api.swasthyaai_api.id
  resource_id = aws_api_gateway_resource.insurance_analyze.id
  http_method = aws_api_gateway_method.insurance_analyze_post.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.insurance_analyzer.invoke_arn
}

# /appointments resource
resource "aws_api_gateway_resource" "appointments" {
  rest_api_id = aws_api_gateway_rest_api.swasthyaai_api.id
  parent_id   = aws_api_gateway_rest_api.swasthyaai_api.root_resource_id
  path_part   = "appointments"
}

resource "aws_api_gateway_resource" "appointments_book" {
  rest_api_id = aws_api_gateway_rest_api.swasthyaai_api.id
  parent_id   = aws_api_gateway_resource.appointments.id
  path_part   = "book"
}

resource "aws_api_gateway_method" "appointments_book_post" {
  rest_api_id   = aws_api_gateway_rest_api.swasthyaai_api.id
  resource_id   = aws_api_gateway_resource.appointments_book.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "appointments_book_lambda" {
  rest_api_id = aws_api_gateway_rest_api.swasthyaai_api.id
  resource_id = aws_api_gateway_resource.appointments_book.id
  http_method = aws_api_gateway_method.appointments_book_post.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.appointment_booking.invoke_arn
}

# /appointments/patient resource
resource "aws_api_gateway_resource" "appointments_patient" {
  rest_api_id = aws_api_gateway_rest_api.swasthyaai_api.id
  parent_id   = aws_api_gateway_resource.appointments.id
  path_part   = "patient"
}

resource "aws_api_gateway_method" "appointments_patient_get" {
  rest_api_id   = aws_api_gateway_rest_api.swasthyaai_api.id
  resource_id   = aws_api_gateway_resource.appointments_patient.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "appointments_patient_lambda" {
  rest_api_id = aws_api_gateway_rest_api.swasthyaai_api.id
  resource_id = aws_api_gateway_resource.appointments_patient.id
  http_method = aws_api_gateway_method.appointments_patient_get.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.appointment_booking.invoke_arn
}

# /appointments/doctor resource
resource "aws_api_gateway_resource" "appointments_doctor" {
  rest_api_id = aws_api_gateway_rest_api.swasthyaai_api.id
  parent_id   = aws_api_gateway_resource.appointments.id
  path_part   = "doctor"
}

resource "aws_api_gateway_method" "appointments_doctor_get" {
  rest_api_id   = aws_api_gateway_rest_api.swasthyaai_api.id
  resource_id   = aws_api_gateway_resource.appointments_doctor.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "appointments_doctor_lambda" {
  rest_api_id = aws_api_gateway_rest_api.swasthyaai_api.id
  resource_id = aws_api_gateway_resource.appointments_doctor.id
  http_method = aws_api_gateway_method.appointments_doctor_get.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.appointment_booking.invoke_arn
}

# Lambda permissions for API Gateway
resource "aws_lambda_permission" "chat_api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.patient_chatbot.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.swasthyaai_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "clinical_api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.clinical_summarizer_nova.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.swasthyaai_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "insurance_api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.insurance_analyzer.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.swasthyaai_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "appointments_api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.appointment_booking.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.swasthyaai_api.execution_arn}/*/*"
}

# CORS configuration for all methods
module "cors_clinical_generate" {
  source = "squidfunk/api-gateway-enable-cors/aws"
  version = "0.3.3"

  api_id          = aws_api_gateway_rest_api.swasthyaai_api.id
  api_resource_id = aws_api_gateway_resource.clinical_generate.id
}

module "cors_insurance_analyze" {
  source = "squidfunk/api-gateway-enable-cors/aws"
  version = "0.3.3"

  api_id          = aws_api_gateway_rest_api.swasthyaai_api.id
  api_resource_id = aws_api_gateway_resource.insurance_analyze.id
}

module "cors_appointments_book" {
  source = "squidfunk/api-gateway-enable-cors/aws"
  version = "0.3.3"

  api_id          = aws_api_gateway_rest_api.swasthyaai_api.id
  api_resource_id = aws_api_gateway_resource.appointments_book.id
}

module "cors_appointments_patient" {
  source = "squidfunk/api-gateway-enable-cors/aws"
  version = "0.3.3"

  api_id          = aws_api_gateway_rest_api.swasthyaai_api.id
  api_resource_id = aws_api_gateway_resource.appointments_patient.id
}

module "cors_appointments_doctor" {
  source = "squidfunk/api-gateway-enable-cors/aws"
  version = "0.3.3"

  api_id          = aws_api_gateway_rest_api.swasthyaai_api.id
  api_resource_id = aws_api_gateway_resource.appointments_doctor.id
}

# API Gateway Deployment
resource "aws_api_gateway_deployment" "swasthyaai_deployment" {
  depends_on = [
    aws_api_gateway_integration.chat_lambda,
    aws_api_gateway_integration.clinical_generate_lambda,
    aws_api_gateway_integration.insurance_analyze_lambda,
    aws_api_gateway_integration.appointments_book_lambda,
    aws_api_gateway_integration.appointments_patient_lambda,
    aws_api_gateway_integration.appointments_doctor_lambda,
    aws_api_gateway_integration.auth_signup_lambda,
    aws_api_gateway_integration.auth_login_lambda,
    aws_api_gateway_integration.auth_profile_get_lambda,
    aws_api_gateway_integration.auth_profile_put_lambda,
    aws_api_gateway_integration.auth_doctors_lambda,
    aws_api_gateway_integration.auth_patients_lambda,
    aws_api_gateway_integration.history_patient_lambda,
  ]

  rest_api_id = aws_api_gateway_rest_api.swasthyaai_api.id
  
  # Force new deployment
  triggers = {
    redeployment = timestamp()
  }

  lifecycle {
    create_before_destroy = true
  }
}

# API Gateway Stage
resource "aws_api_gateway_stage" "swasthyaai_stage" {
  deployment_id = aws_api_gateway_deployment.swasthyaai_deployment.id
  rest_api_id   = aws_api_gateway_rest_api.swasthyaai_api.id
  stage_name    = var.environment

  xray_tracing_enabled = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway_logs.arn
    format = jsonencode({
      requestId      = "$context.requestId"
      ip             = "$context.identity.sourceIp"
      caller         = "$context.identity.caller"
      user           = "$context.identity.user"
      requestTime    = "$context.requestTime"
      httpMethod     = "$context.httpMethod"
      resourcePath   = "$context.resourcePath"
      status         = "$context.status"
      protocol       = "$context.protocol"
      responseLength = "$context.responseLength"
    })
  }

  tags = var.common_tags

  depends_on = [aws_api_gateway_account.main]
}

# CloudWatch Log Group for API Gateway
resource "aws_cloudwatch_log_group" "api_gateway_logs" {
  name              = "/aws/apigateway/${var.project_name}-${var.environment}"
  retention_in_days = 14
  tags              = var.common_tags
}

# Usage Plan
resource "aws_api_gateway_usage_plan" "swasthyaai_usage_plan" {
  name        = "${var.project_name}-usage-plan-${var.environment}"
  description = "Usage plan for SwasthyaAI API"

  api_stages {
    api_id = aws_api_gateway_rest_api.swasthyaai_api.id
    stage  = aws_api_gateway_stage.swasthyaai_stage.stage_name
  }

  quota_settings {
    limit  = 10000
    period = "DAY"
  }

  throttle_settings {
    burst_limit = 100
    rate_limit  = 50
  }

  tags = var.common_tags
}

# Outputs
output "api_gateway_url" {
  description = "API Gateway invoke URL"
  value       = aws_api_gateway_stage.swasthyaai_stage.invoke_url
}

output "api_gateway_id" {
  description = "API Gateway ID"
  value       = aws_api_gateway_rest_api.swasthyaai_api.id
}


# /auth resource
resource "aws_api_gateway_resource" "auth" {
  rest_api_id = aws_api_gateway_rest_api.swasthyaai_api.id
  parent_id   = aws_api_gateway_rest_api.swasthyaai_api.root_resource_id
  path_part   = "auth"
}

# /auth/signup
resource "aws_api_gateway_resource" "auth_signup" {
  rest_api_id = aws_api_gateway_rest_api.swasthyaai_api.id
  parent_id   = aws_api_gateway_resource.auth.id
  path_part   = "signup"
}

resource "aws_api_gateway_method" "auth_signup_post" {
  rest_api_id   = aws_api_gateway_rest_api.swasthyaai_api.id
  resource_id   = aws_api_gateway_resource.auth_signup.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "auth_signup_lambda" {
  rest_api_id = aws_api_gateway_rest_api.swasthyaai_api.id
  resource_id = aws_api_gateway_resource.auth_signup.id
  http_method = aws_api_gateway_method.auth_signup_post.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.auth.invoke_arn
}

# /auth/login
resource "aws_api_gateway_resource" "auth_login" {
  rest_api_id = aws_api_gateway_rest_api.swasthyaai_api.id
  parent_id   = aws_api_gateway_resource.auth.id
  path_part   = "login"
}

resource "aws_api_gateway_method" "auth_login_post" {
  rest_api_id   = aws_api_gateway_rest_api.swasthyaai_api.id
  resource_id   = aws_api_gateway_resource.auth_login.id
  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "auth_login_lambda" {
  rest_api_id = aws_api_gateway_rest_api.swasthyaai_api.id
  resource_id = aws_api_gateway_resource.auth_login.id
  http_method = aws_api_gateway_method.auth_login_post.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.auth.invoke_arn
}

# /auth/profile
resource "aws_api_gateway_resource" "auth_profile" {
  rest_api_id = aws_api_gateway_rest_api.swasthyaai_api.id
  parent_id   = aws_api_gateway_resource.auth.id
  path_part   = "profile"
}

resource "aws_api_gateway_method" "auth_profile_get" {
  rest_api_id   = aws_api_gateway_rest_api.swasthyaai_api.id
  resource_id   = aws_api_gateway_resource.auth_profile.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "auth_profile_get_lambda" {
  rest_api_id = aws_api_gateway_rest_api.swasthyaai_api.id
  resource_id = aws_api_gateway_resource.auth_profile.id
  http_method = aws_api_gateway_method.auth_profile_get.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.auth.invoke_arn
}

resource "aws_api_gateway_method" "auth_profile_put" {
  rest_api_id   = aws_api_gateway_rest_api.swasthyaai_api.id
  resource_id   = aws_api_gateway_resource.auth_profile.id
  http_method   = "PUT"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "auth_profile_put_lambda" {
  rest_api_id = aws_api_gateway_rest_api.swasthyaai_api.id
  resource_id = aws_api_gateway_resource.auth_profile.id
  http_method = aws_api_gateway_method.auth_profile_put.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.auth.invoke_arn
}

# /auth/doctors
resource "aws_api_gateway_resource" "auth_doctors" {
  rest_api_id = aws_api_gateway_rest_api.swasthyaai_api.id
  parent_id   = aws_api_gateway_resource.auth.id
  path_part   = "doctors"
}

resource "aws_api_gateway_method" "auth_doctors_get" {
  rest_api_id   = aws_api_gateway_rest_api.swasthyaai_api.id
  resource_id   = aws_api_gateway_resource.auth_doctors.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "auth_doctors_lambda" {
  rest_api_id = aws_api_gateway_rest_api.swasthyaai_api.id
  resource_id = aws_api_gateway_resource.auth_doctors.id
  http_method = aws_api_gateway_method.auth_doctors_get.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.auth.invoke_arn
}

# /auth/patients
resource "aws_api_gateway_resource" "auth_patients" {
  rest_api_id = aws_api_gateway_rest_api.swasthyaai_api.id
  parent_id   = aws_api_gateway_resource.auth.id
  path_part   = "patients"
}

resource "aws_api_gateway_method" "auth_patients_get" {
  rest_api_id   = aws_api_gateway_rest_api.swasthyaai_api.id
  resource_id   = aws_api_gateway_resource.auth_patients.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "auth_patients_lambda" {
  rest_api_id = aws_api_gateway_rest_api.swasthyaai_api.id
  resource_id = aws_api_gateway_resource.auth_patients.id
  http_method = aws_api_gateway_method.auth_patients_get.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.auth.invoke_arn
}

# /history resource
resource "aws_api_gateway_resource" "history" {
  rest_api_id = aws_api_gateway_rest_api.swasthyaai_api.id
  parent_id   = aws_api_gateway_rest_api.swasthyaai_api.root_resource_id
  path_part   = "history"
}

# /history/patient
resource "aws_api_gateway_resource" "history_patient" {
  rest_api_id = aws_api_gateway_rest_api.swasthyaai_api.id
  parent_id   = aws_api_gateway_resource.history.id
  path_part   = "patient"
}

resource "aws_api_gateway_method" "history_patient_get" {
  rest_api_id   = aws_api_gateway_rest_api.swasthyaai_api.id
  resource_id   = aws_api_gateway_resource.history_patient.id
  http_method   = "GET"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "history_patient_lambda" {
  rest_api_id = aws_api_gateway_rest_api.swasthyaai_api.id
  resource_id = aws_api_gateway_resource.history_patient.id
  http_method = aws_api_gateway_method.history_patient_get.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"
  uri                     = aws_lambda_function.patient_history.invoke_arn
}

# Lambda permissions for new endpoints
resource "aws_lambda_permission" "auth_api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.auth.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.swasthyaai_api.execution_arn}/*/*"
}

resource "aws_lambda_permission" "patient_history_api_gateway" {
  statement_id  = "AllowAPIGatewayInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.patient_history.function_name
  principal     = "apigateway.amazonaws.com"
  source_arn    = "${aws_api_gateway_rest_api.swasthyaai_api.execution_arn}/*/*"
}

# CORS for auth endpoints
module "cors_auth_signup" {
  source  = "squidfunk/api-gateway-enable-cors/aws"
  version = "0.3.3"

  api_id          = aws_api_gateway_rest_api.swasthyaai_api.id
  api_resource_id = aws_api_gateway_resource.auth_signup.id
}

module "cors_auth_login" {
  source  = "squidfunk/api-gateway-enable-cors/aws"
  version = "0.3.3"

  api_id          = aws_api_gateway_rest_api.swasthyaai_api.id
  api_resource_id = aws_api_gateway_resource.auth_login.id
}

module "cors_auth_profile" {
  source  = "squidfunk/api-gateway-enable-cors/aws"
  version = "0.3.3"

  api_id          = aws_api_gateway_rest_api.swasthyaai_api.id
  api_resource_id = aws_api_gateway_resource.auth_profile.id
}

module "cors_auth_doctors" {
  source  = "squidfunk/api-gateway-enable-cors/aws"
  version = "0.3.3"

  api_id          = aws_api_gateway_rest_api.swasthyaai_api.id
  api_resource_id = aws_api_gateway_resource.auth_doctors.id
}

module "cors_auth_patients" {
  source  = "squidfunk/api-gateway-enable-cors/aws"
  version = "0.3.3"

  api_id          = aws_api_gateway_rest_api.swasthyaai_api.id
  api_resource_id = aws_api_gateway_resource.auth_patients.id
}

module "cors_history_patient" {
  source  = "squidfunk/api-gateway-enable-cors/aws"
  version = "0.3.3"

  api_id          = aws_api_gateway_rest_api.swasthyaai_api.id
  api_resource_id = aws_api_gateway_resource.history_patient.id
}
