# Amazon Bedrock Configuration for SwasthyaAI
# Note: Bedrock model access must be enabled manually in AWS Console

# Data source for Bedrock foundation model
data "aws_bedrock_foundation_model" "nova_lite" {
  model_id = "amazon.nova-2-lite-v1:0"
}

# IAM policy for Bedrock access
resource "aws_iam_policy" "bedrock_invoke_policy" {
  name        = "${var.project_name}-bedrock-invoke-policy-${var.environment}"
  description = "Policy for invoking Amazon Bedrock models"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "bedrock:InvokeModel",
          "bedrock:InvokeModelWithResponseStream"
        ]
        Resource = [
          "arn:aws:bedrock:${var.aws_region}::foundation-model/amazon.nova-2-lite-v1:0"
        ]
      }
    ]
  })

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-bedrock-policy-${var.environment}"
    }
  )
}

# Attach Bedrock policy to Lambda execution role
resource "aws_iam_role_policy_attachment" "lambda_bedrock_policy" {
  role       = aws_iam_role.lambda_execution_role.name
  policy_arn = aws_iam_policy.bedrock_invoke_policy.arn
}

# CloudWatch Log Group for Bedrock API calls
resource "aws_cloudwatch_log_group" "bedrock_logs" {
  name              = "/aws/bedrock/${var.project_name}-${var.environment}"
  retention_in_days = 30

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-bedrock-logs-${var.environment}"
    }
  )
}

# CloudWatch Metric Alarm for Bedrock throttling
resource "aws_cloudwatch_metric_alarm" "bedrock_throttle_alarm" {
  alarm_name          = "${var.project_name}-bedrock-throttle-${var.environment}"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name         = "ModelInvocationThrottles"
  namespace           = "AWS/Bedrock"
  period              = "300"
  statistic           = "Sum"
  threshold           = "10"
  alarm_description   = "This metric monitors Bedrock API throttling"
  alarm_actions       = [aws_sns_topic.alerts.arn]

  dimensions = {
    ModelId = "amazon.nova-2-lite-v1:0"
  }

  tags = var.common_tags
}

# Output Bedrock model information
output "bedrock_model_id" {
  description = "Bedrock model ID being used"
  value       = data.aws_bedrock_foundation_model.nova_lite.model_id
}

output "bedrock_policy_arn" {
  description = "ARN of the Bedrock invoke policy"
  value       = aws_iam_policy.bedrock_invoke_policy.arn
}
