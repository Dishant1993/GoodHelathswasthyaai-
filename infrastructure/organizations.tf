# SwasthyaAI - AWS Organizations Configuration
# This file defines the AWS Organization structure with separate accounts for dev, staging, and prod

# AWS Organization
resource "aws_organizations_organization" "swasthyaai" {
  aws_service_access_principals = [
    "cloudtrail.amazonaws.com",
    "config.amazonaws.com",
    "sso.amazonaws.com",
    "guardduty.amazonaws.com",
    "securityhub.amazonaws.com"
  ]

  feature_set = "ALL"

  enabled_policy_types = [
    "SERVICE_CONTROL_POLICY",
    "TAG_POLICY"
  ]
}

# Organizational Units
resource "aws_organizations_organizational_unit" "workloads" {
  name      = "Workloads"
  parent_id = aws_organizations_organization.swasthyaai.roots[0].id
}

resource "aws_organizations_organizational_unit" "security" {
  name      = "Security"
  parent_id = aws_organizations_organization.swasthyaai.roots[0].id
}

# Development Account
resource "aws_organizations_account" "dev" {
  name      = "swasthyaai-dev"
  email     = var.dev_account_email
  parent_id = aws_organizations_organizational_unit.workloads.id

  role_name = "OrganizationAccountAccessRole"

  tags = merge(
    local.common_tags,
    {
      Name        = "SwasthyaAI Development"
      Environment = "dev"
      Purpose     = "Development and testing environment"
    }
  )

  lifecycle {
    prevent_destroy = true
  }
}

# Staging Account
resource "aws_organizations_account" "staging" {
  name      = "swasthyaai-staging"
  email     = var.staging_account_email
  parent_id = aws_organizations_organizational_unit.workloads.id

  role_name = "OrganizationAccountAccessRole"

  tags = merge(
    local.common_tags,
    {
      Name        = "SwasthyaAI Staging"
      Environment = "staging"
      Purpose     = "Pre-production validation environment"
    }
  )

  lifecycle {
    prevent_destroy = true
  }
}

# Production Account
resource "aws_organizations_account" "prod" {
  name      = "swasthyaai-prod"
  email     = var.prod_account_email
  parent_id = aws_organizations_organizational_unit.workloads.id

  role_name = "OrganizationAccountAccessRole"

  tags = merge(
    local.common_tags,
    {
      Name        = "SwasthyaAI Production"
      Environment = "prod"
      Purpose     = "Production environment for live deployment"
    }
  )

  lifecycle {
    prevent_destroy = true
  }
}

# Security/Audit Account
resource "aws_organizations_account" "security" {
  name      = "swasthyaai-security"
  email     = var.security_account_email
  parent_id = aws_organizations_organizational_unit.security.id

  role_name = "OrganizationAccountAccessRole"

  tags = merge(
    local.common_tags,
    {
      Name        = "SwasthyaAI Security"
      Environment = "shared"
      Purpose     = "Centralized security and audit logging"
    }
  )

  lifecycle {
    prevent_destroy = true
  }
}

# Service Control Policies (SCPs)

# Base SCP - Deny leaving organization
resource "aws_organizations_policy" "deny_leave_organization" {
  name        = "DenyLeaveOrganization"
  description = "Prevent accounts from leaving the organization"
  type        = "SERVICE_CONTROL_POLICY"

  content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Deny"
        Action   = "organizations:LeaveOrganization"
        Resource = "*"
      }
    ]
  })
}

# SCP - Enforce encryption
resource "aws_organizations_policy" "enforce_encryption" {
  name        = "EnforceEncryption"
  description = "Require encryption for S3, EBS, and RDS"
  type        = "SERVICE_CONTROL_POLICY"

  content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DenyUnencryptedS3Uploads"
        Effect = "Deny"
        Action = "s3:PutObject"
        Resource = "*"
        Condition = {
          StringNotEquals = {
            "s3:x-amz-server-side-encryption" = ["AES256", "aws:kms"]
          }
        }
      },
      {
        Sid    = "DenyUnencryptedEBSVolumes"
        Effect = "Deny"
        Action = [
          "ec2:CreateVolume",
          "ec2:RunInstances"
        ]
        Resource = "*"
        Condition = {
          Bool = {
            "ec2:Encrypted" = "false"
          }
        }
      },
      {
        Sid    = "DenyUnencryptedRDS"
        Effect = "Deny"
        Action = [
          "rds:CreateDBInstance",
          "rds:CreateDBCluster"
        ]
        Resource = "*"
        Condition = {
          Bool = {
            "rds:StorageEncrypted" = "false"
          }
        }
      }
    ]
  })
}

# SCP - Enforce region restriction (India regions only)
resource "aws_organizations_policy" "enforce_india_regions" {
  name        = "EnforceIndiaRegions"
  description = "Restrict operations to India regions (ap-south-1, ap-south-2)"
  type        = "SERVICE_CONTROL_POLICY"

  content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DenyNonIndiaRegions"
        Effect = "Deny"
        NotAction = [
          "iam:*",
          "organizations:*",
          "route53:*",
          "cloudfront:*",
          "support:*",
          "budgets:*",
          "ce:*",
          "aws-portal:*"
        ]
        Resource = "*"
        Condition = {
          StringNotEquals = {
            "aws:RequestedRegion" = [
              "ap-south-1",
              "ap-south-2"
            ]
          }
        }
      }
    ]
  })
}

# SCP - Require MFA for sensitive operations
resource "aws_organizations_policy" "require_mfa" {
  name        = "RequireMFA"
  description = "Require MFA for sensitive operations"
  type        = "SERVICE_CONTROL_POLICY"

  content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DenyWithoutMFA"
        Effect = "Deny"
        Action = [
          "ec2:StopInstances",
          "ec2:TerminateInstances",
          "rds:DeleteDBInstance",
          "rds:DeleteDBCluster",
          "s3:DeleteBucket",
          "dynamodb:DeleteTable"
        ]
        Resource = "*"
        Condition = {
          BoolIfExists = {
            "aws:MultiFactorAuthPresent" = "false"
          }
        }
      }
    ]
  })
}

# SCP - Deny root user access
resource "aws_organizations_policy" "deny_root_user" {
  name        = "DenyRootUser"
  description = "Deny root user access except for account management"
  type        = "SERVICE_CONTROL_POLICY"

  content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DenyRootUserAccess"
        Effect = "Deny"
        NotAction = [
          "iam:CreateVirtualMFADevice",
          "iam:EnableMFADevice",
          "iam:ListMFADevices",
          "iam:ListUsers",
          "iam:ListVirtualMFADevices",
          "iam:ResyncMFADevice",
          "sts:GetSessionToken"
        ]
        Resource = "*"
        Condition = {
          StringLike = {
            "aws:PrincipalArn" = "arn:aws:iam::*:root"
          }
        }
      }
    ]
  })
}

# Attach SCPs to Workloads OU
resource "aws_organizations_policy_attachment" "workloads_deny_leave" {
  policy_id = aws_organizations_policy.deny_leave_organization.id
  target_id = aws_organizations_organizational_unit.workloads.id
}

resource "aws_organizations_policy_attachment" "workloads_enforce_encryption" {
  policy_id = aws_organizations_policy.enforce_encryption.id
  target_id = aws_organizations_organizational_unit.workloads.id
}

resource "aws_organizations_policy_attachment" "workloads_enforce_regions" {
  policy_id = aws_organizations_policy.enforce_india_regions.id
  target_id = aws_organizations_organizational_unit.workloads.id
}

# Commented out due to AWS policy attachment limit per OU
# resource "aws_organizations_policy_attachment" "workloads_require_mfa" {
#   policy_id = aws_organizations_policy.require_mfa.id
#   target_id = aws_organizations_organizational_unit.workloads.id
# }

resource "aws_organizations_policy_attachment" "workloads_deny_root" {
  policy_id = aws_organizations_policy.deny_root_user.id
  target_id = aws_organizations_organizational_unit.workloads.id
}

# Attach SCPs to Security OU
resource "aws_organizations_policy_attachment" "security_deny_leave" {
  policy_id = aws_organizations_policy.deny_leave_organization.id
  target_id = aws_organizations_organizational_unit.security.id
}

resource "aws_organizations_policy_attachment" "security_enforce_encryption" {
  policy_id = aws_organizations_policy.enforce_encryption.id
  target_id = aws_organizations_organizational_unit.security.id
}

# Outputs
output "organization_id" {
  description = "AWS Organization ID"
  value       = aws_organizations_organization.swasthyaai.id
}

output "organization_arn" {
  description = "AWS Organization ARN"
  value       = aws_organizations_organization.swasthyaai.arn
}

output "dev_account_id" {
  description = "Development account ID"
  value       = aws_organizations_account.dev.id
}

output "staging_account_id" {
  description = "Staging account ID"
  value       = aws_organizations_account.staging.id
}

output "prod_account_id" {
  description = "Production account ID"
  value       = aws_organizations_account.prod.id
}

output "security_account_id" {
  description = "Security account ID"
  value       = aws_organizations_account.security.id
}

output "workloads_ou_id" {
  description = "Workloads Organizational Unit ID"
  value       = aws_organizations_organizational_unit.workloads.id
}

output "security_ou_id" {
  description = "Security Organizational Unit ID"
  value       = aws_organizations_organizational_unit.security.id
}
