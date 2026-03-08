# SwasthyaAI - S3 Buckets Configuration

# KMS Key for S3 Encryption
resource "aws_kms_key" "s3" {
  description             = "KMS key for S3 encryption"
  deletion_window_in_days = 10
  enable_key_rotation     = true
  
  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-s3-kms"
  })
}

resource "aws_kms_alias" "s3" {
  name          = "alias/${var.project_name}-${var.environment}-s3"
  target_key_id = aws_kms_key.s3.key_id
}

# Clinical Audio Bucket
resource "aws_s3_bucket" "clinical_audio" {
  bucket = "${var.project_name}-${var.environment}-clinical-audio"
  
  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-clinical-audio"
  })
}

resource "aws_s3_bucket_versioning" "clinical_audio" {
  bucket = aws_s3_bucket.clinical_audio.id
  
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "clinical_audio" {
  bucket = aws_s3_bucket.clinical_audio.id
  
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.s3.arn
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "clinical_audio" {
  bucket = aws_s3_bucket.clinical_audio.id
  
  rule {
    id     = "delete-old-audio"
    status = "Enabled"
    
    expiration {
      days = 90
    }
  }
}

resource "aws_s3_bucket_public_access_block" "clinical_audio" {
  bucket = aws_s3_bucket.clinical_audio.id
  
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Clinical Documents Bucket
resource "aws_s3_bucket" "clinical_documents" {
  bucket = "${var.project_name}-${var.environment}-clinical-documents"
  
  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-clinical-documents"
  })
}

resource "aws_s3_bucket_versioning" "clinical_documents" {
  bucket = aws_s3_bucket.clinical_documents.id
  
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "clinical_documents" {
  bucket = aws_s3_bucket.clinical_documents.id
  
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.s3.arn
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "clinical_documents" {
  bucket = aws_s3_bucket.clinical_documents.id
  
  rule {
    id     = "transition-to-glacier"
    status = "Enabled"
    
    transition {
      days          = 365
      storage_class = "GLACIER"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "clinical_documents" {
  bucket = aws_s3_bucket.clinical_documents.id
  
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# AI Model Artifacts Bucket
resource "aws_s3_bucket" "ai_model_artifacts" {
  bucket = "${var.project_name}-${var.environment}-ai-model-artifacts"
  
  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-ai-model-artifacts"
  })
}

resource "aws_s3_bucket_versioning" "ai_model_artifacts" {
  bucket = aws_s3_bucket.ai_model_artifacts.id
  
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "ai_model_artifacts" {
  bucket = aws_s3_bucket.ai_model_artifacts.id
  
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.s3.arn
    }
  }
}

resource "aws_s3_bucket_public_access_block" "ai_model_artifacts" {
  bucket = aws_s3_bucket.ai_model_artifacts.id
  
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Audit Logs Bucket
resource "aws_s3_bucket" "audit_logs" {
  bucket = "${var.project_name}-${var.environment}-audit-logs"
  
  tags = merge(local.common_tags, {
    Name = "${var.project_name}-${var.environment}-audit-logs"
  })
}

resource "aws_s3_bucket_versioning" "audit_logs" {
  bucket = aws_s3_bucket.audit_logs.id
  
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "audit_logs" {
  bucket = aws_s3_bucket.audit_logs.id
  
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm     = "aws:kms"
      kms_master_key_id = aws_kms_key.s3.arn
    }
  }
}

resource "aws_s3_bucket_lifecycle_configuration" "audit_logs" {
  bucket = aws_s3_bucket.audit_logs.id
  
  rule {
    id     = "retain-audit-logs"
    status = "Enabled"
    
    transition {
      days          = 90
      storage_class = "STANDARD_IA"
    }
    
    transition {
      days          = 365
      storage_class = "GLACIER"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "audit_logs" {
  bucket = aws_s3_bucket.audit_logs.id
  
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Outputs
output "s3_buckets" {
  description = "S3 bucket names and ARNs"
  value = {
    clinical_audio = {
      name = aws_s3_bucket.clinical_audio.bucket
      arn  = aws_s3_bucket.clinical_audio.arn
    }
    clinical_documents = {
      name = aws_s3_bucket.clinical_documents.bucket
      arn  = aws_s3_bucket.clinical_documents.arn
    }
    ai_model_artifacts = {
      name = aws_s3_bucket.ai_model_artifacts.bucket
      arn  = aws_s3_bucket.ai_model_artifacts.arn
    }
    audit_logs = {
      name = aws_s3_bucket.audit_logs.bucket
      arn  = aws_s3_bucket.audit_logs.arn
    }
  }
}


# Conversations Bucket
resource "aws_s3_bucket" "conversations" {
  bucket = "${var.project_name}-conversations-${var.environment}-${data.aws_caller_identity.current.account_id}"

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-conversations-${var.environment}"
    }
  )
}

resource "aws_s3_bucket_server_side_encryption_configuration" "conversations" {
  bucket = aws_s3_bucket.conversations.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "conversations" {
  bucket = aws_s3_bucket.conversations.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "conversations" {
  bucket = aws_s3_bucket.conversations.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Clinical Logs Bucket
resource "aws_s3_bucket" "clinical_logs" {
  bucket = "${var.project_name}-clinical-logs-${var.environment}-${data.aws_caller_identity.current.account_id}"

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-clinical-logs-${var.environment}"
    }
  )
}

resource "aws_s3_bucket_server_side_encryption_configuration" "clinical_logs" {
  bucket = aws_s3_bucket.clinical_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "clinical_logs" {
  bucket = aws_s3_bucket.clinical_logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "clinical_logs" {
  bucket = aws_s3_bucket.clinical_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Insurance Policies Bucket
resource "aws_s3_bucket" "insurance_policies" {
  bucket = "${var.project_name}-insurance-policies-${var.environment}-${data.aws_caller_identity.current.account_id}"

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-insurance-policies-${var.environment}"
    }
  )
}

resource "aws_s3_bucket_server_side_encryption_configuration" "insurance_policies" {
  bucket = aws_s3_bucket.insurance_policies.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "insurance_policies" {
  bucket = aws_s3_bucket.insurance_policies.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "insurance_policies" {
  bucket = aws_s3_bucket.insurance_policies.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Insurance Logs Bucket
resource "aws_s3_bucket" "insurance_logs" {
  bucket = "${var.project_name}-insurance-logs-${var.environment}-${data.aws_caller_identity.current.account_id}"

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-insurance-logs-${var.environment}"
    }
  )
}

resource "aws_s3_bucket_server_side_encryption_configuration" "insurance_logs" {
  bucket = aws_s3_bucket.insurance_logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "insurance_logs" {
  bucket = aws_s3_bucket.insurance_logs.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "insurance_logs" {
  bucket = aws_s3_bucket.insurance_logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Frontend Hosting Bucket
resource "aws_s3_bucket" "frontend" {
  bucket = "${var.project_name}-frontend-${var.environment}-${data.aws_caller_identity.current.account_id}"

  tags = merge(
    var.common_tags,
    {
      Name = "${var.project_name}-frontend-${var.environment}"
    }
  )
}

resource "aws_s3_bucket_website_configuration" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  index_document {
    suffix = "index.html"
  }

  error_document {
    key = "index.html"
  }
}

resource "aws_s3_bucket_public_access_block" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid       = "PublicReadGetObject"
        Effect    = "Allow"
        Principal = "*"
        Action    = "s3:GetObject"
        Resource  = "${aws_s3_bucket.frontend.arn}/*"
      }
    ]
  })
}

# Additional S3 bucket outputs
output "s3_additional_buckets" {
  description = "Additional S3 bucket names"
  value = {
    conversations       = aws_s3_bucket.conversations.id
    clinical_logs       = aws_s3_bucket.clinical_logs.id
    insurance_policies  = aws_s3_bucket.insurance_policies.id
    insurance_logs      = aws_s3_bucket.insurance_logs.id
    frontend            = aws_s3_bucket.frontend.id
  }
}

output "frontend_website_endpoint" {
  description = "Frontend website endpoint"
  value       = aws_s3_bucket_website_configuration.frontend.website_endpoint
}
