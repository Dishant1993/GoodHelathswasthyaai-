# SwasthyaAI - DynamoDB Tables Configuration

# KMS Key for DynamoDB Encryption
resource "aws_kms_key" "dynamodb" {
  description             = "KMS key for DynamoDB encryption"
  deletion_window_in_days = 10
  enable_key_rotation     = true
  
  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-dynamodb-kms"
  })
}

resource "aws_kms_alias" "dynamodb" {
  name          = "alias/${var.project_name}-${var.environment}-dynamodb"
  target_key_id = aws_kms_key.dynamodb.key_id
}

# Patients Table
resource "aws_dynamodb_table" "patients" {
  name           = "${var.project_name}-${var.environment}-patients"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "patient_id"
  
  attribute {
    name = "patient_id"
    type = "S"
  }
  
  attribute {
    name = "hospital_id"
    type = "S"
  }
  
  attribute {
    name = "created_at"
    type = "S"
  }
  
  global_secondary_index {
    name            = "hospital_id-created_at-index"
    hash_key        = "hospital_id"
    range_key       = "created_at"
    projection_type = "ALL"
  }
  
  point_in_time_recovery {
    enabled = true
  }
  
  server_side_encryption {
    enabled     = true
    kms_key_arn = aws_kms_key.dynamodb.arn
  }
  
  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-patients"
  })
}

# Clinical Notes Table
resource "aws_dynamodb_table" "clinical_notes" {
  name           = "${var.project_name}-${var.environment}-clinical-notes"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "patient_id"
  range_key      = "note_id"
  
  attribute {
    name = "patient_id"
    type = "S"
  }
  
  attribute {
    name = "note_id"
    type = "S"
  }
  
  attribute {
    name = "status"
    type = "S"
  }
  
  attribute {
    name = "created_at"
    type = "S"
  }
  
  global_secondary_index {
    name            = "status-created_at-index"
    hash_key        = "status"
    range_key       = "created_at"
    projection_type = "ALL"
  }
  
  point_in_time_recovery {
    enabled = true
  }
  
  server_side_encryption {
    enabled     = true
    kms_key_arn = aws_kms_key.dynamodb.arn
  }
  
  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES"
  
  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-clinical-notes"
  })
}

# Timeline Table
resource "aws_dynamodb_table" "timeline" {
  name           = "${var.project_name}-${var.environment}-timeline"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "patient_id"
  range_key      = "event_timestamp"
  
  attribute {
    name = "patient_id"
    type = "S"
  }
  
  attribute {
    name = "event_timestamp"
    type = "S"
  }
  
  attribute {
    name = "event_type"
    type = "S"
  }
  
  local_secondary_index {
    name            = "event_type-event_timestamp-index"
    range_key       = "event_type"
    projection_type = "ALL"
  }
  
  point_in_time_recovery {
    enabled = true
  }
  
  server_side_encryption {
    enabled     = true
    kms_key_arn = aws_kms_key.dynamodb.arn
  }
  
  stream_enabled   = true
  stream_view_type = "NEW_AND_OLD_IMAGES"
  
  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-timeline"
  })
}

# Approval Workflow Table
resource "aws_dynamodb_table" "approval_workflow" {
  name           = "${var.project_name}-${var.environment}-approval-workflow"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "workflow_id"
  
  attribute {
    name = "workflow_id"
    type = "S"
  }
  
  attribute {
    name = "assigned_to"
    type = "S"
  }
  
  attribute {
    name = "status"
    type = "S"
  }
  
  global_secondary_index {
    name            = "assigned_to-status-index"
    hash_key        = "assigned_to"
    range_key       = "status"
    projection_type = "ALL"
  }
  
  point_in_time_recovery {
    enabled = true
  }
  
  server_side_encryption {
    enabled     = true
    kms_key_arn = aws_kms_key.dynamodb.arn
  }
  
  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-approval-workflow"
  })
}

# Outputs
output "dynamodb_tables" {
  description = "DynamoDB table names and ARNs"
  value = {
    patients = {
      name = aws_dynamodb_table.patients.name
      arn  = aws_dynamodb_table.patients.arn
    }
    clinical_notes = {
      name = aws_dynamodb_table.clinical_notes.name
      arn  = aws_dynamodb_table.clinical_notes.arn
    }
    timeline = {
      name = aws_dynamodb_table.timeline.name
      arn  = aws_dynamodb_table.timeline.arn
    }
    approval_workflow = {
      name = aws_dynamodb_table.approval_workflow.name
      arn  = aws_dynamodb_table.approval_workflow.arn
    }
  }
}


# Appointments Table
resource "aws_dynamodb_table" "appointments" {
  name           = "${var.project_name}-Appointments-${var.environment}"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "appointment_id"

  attribute {
    name = "appointment_id"
    type = "S"
  }

  attribute {
    name = "patient_id"
    type = "S"
  }

  attribute {
    name = "doctor_id"
    type = "S"
  }

  attribute {
    name = "date"
    type = "S"
  }

  global_secondary_index {
    name            = "PatientIndex"
    hash_key        = "patient_id"
    projection_type = "ALL"
  }

  global_secondary_index {
    name            = "DoctorDateIndex"
    hash_key        = "doctor_id"
    range_key       = "date"
    projection_type = "ALL"
  }

  server_side_encryption {
    enabled = true
  }

  point_in_time_recovery {
    enabled = true
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-appointments-${var.environment}"
    }
  )
}

# SNS Topic for Alerts
resource "aws_sns_topic" "alerts" {
  name = "${var.project_name}-alerts-${var.environment}"

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-alerts-${var.environment}"
    }
  )
}

# Output
output "dynamodb_appointments_table" {
  description = "DynamoDB appointments table name"
  value = {
    appointments = aws_dynamodb_table.appointments.name
  }
}

output "sns_topic_arn" {
  description = "SNS topic ARN for alerts"
  value       = aws_sns_topic.alerts.arn
}


# Users Table (for authentication)
resource "aws_dynamodb_table" "users" {
  name           = "${var.project_name}-${var.environment}-users"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "email"
  
  attribute {
    name = "email"
    type = "S"
  }
  
  attribute {
    name = "user_id"
    type = "S"
  }
  
  attribute {
    name = "role"
    type = "S"
  }
  
  global_secondary_index {
    name            = "UserIdIndex"
    hash_key        = "user_id"
    projection_type = "ALL"
  }
  
  global_secondary_index {
    name            = "RoleIndex"
    hash_key        = "role"
    projection_type = "ALL"
  }
  
  point_in_time_recovery {
    enabled = true
  }
  
  server_side_encryption {
    enabled     = true
    kms_key_arn = aws_kms_key.dynamodb.arn
  }
  
  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-users"
  })
}

# Insurance Checks Table
resource "aws_dynamodb_table" "insurance_checks" {
  name           = "${var.project_name}-${var.environment}-insurance-checks"
  billing_mode   = "PAY_PER_REQUEST"
  hash_key       = "check_id"
  
  attribute {
    name = "check_id"
    type = "S"
  }
  
  attribute {
    name = "patient_id"
    type = "S"
  }
  
  attribute {
    name = "timestamp"
    type = "S"
  }
  
  global_secondary_index {
    name            = "PatientIndex"
    hash_key        = "patient_id"
    range_key       = "timestamp"
    projection_type = "ALL"
  }
  
  point_in_time_recovery {
    enabled = true
  }
  
  server_side_encryption {
    enabled     = true
    kms_key_arn = aws_kms_key.dynamodb.arn
  }
  
  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-insurance-checks"
  })
}
