# Get all OU IDs for policy attachment
locals {
  all_ou_ids = [
    aws_organizations_organizational_unit.security.id,
    aws_organizations_organizational_unit.production.id,
    aws_organizations_organizational_unit.sandbox.id
  ]
}

# Region Lock SCP
module "region_lock" {
  source = "./modules/scp"

  name        = "RegionLock"
  description = "Restricts AWS operations to specific regions"
  policy_content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Deny"
        Action   = "*"
        Resource = "*"
        Condition = {
          StringNotEquals = {
            "aws:RequestedRegion" : concat([var.aws_region], var.aws_additional_regions)
          }
        }
      }
    ]
  })

  target_ou_ids = local.all_ou_ids
  tags = {
    Purpose = "region-restriction"
  }
}

# Root User Protection SCP
module "protect_root" {
  source = "./modules/scp"

  name        = "ProtectRootUser"
  description = "Prevents use of the root user for any operations"
  policy_content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "DenyRootUser"
        Effect   = "Deny"
        Action   = "*"
        Resource = "*"
        Condition = {
          StringLike = {
            "aws:PrincipalArn" : ["arn:aws:iam::*:root"]
          }
        }
      }
    ]
  })

  target_ou_ids = local.all_ou_ids
  tags = {
    Purpose = "security"
  }
}

# MFA Requirement SCP
module "require_mfa" {
  source = "./modules/scp"

  name        = "RequireMFA"
  description = "Requires MFA for all non-service IAM users"
  policy_content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "DenyNoMFA"
        Effect   = "Deny"
        Action   = "*"
        Resource = "*"
        Condition = {
          BoolIfExists = {
            "aws:MultiFactorAuthPresent" : "false"
          }
          StringNotLike = {
            "aws:PrincipalArn" : [
              "arn:aws:iam::*:role/*",
              "arn:aws:iam::*:user/service/*",
            ]
          }
        }
      }
    ]
  })

  target_ou_ids = local.all_ou_ids
  tags = {
    Purpose = "security"
  }
}

# Critical Resource Protection SCP
module "protect_resources" {
  source = "./modules/scp"

  name        = "ProtectCriticalResources"
  description = "Prevents deletion or modification of critical resources"
  policy_content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ProtectIAM"
        Effect = "Deny"
        Action = [
          "iam:DeleteAccountPasswordPolicy",
          "iam:DeleteRole",
          "iam:DeleteRolePolicy",
          "iam:DeleteUserPolicy",
          "iam:DeleteVirtualMFADevice",
          "iam:DetachRolePolicy",
          "iam:UpdateAccountPasswordPolicy"
        ]
        Resource = "*"
        Condition = {
          StringNotLike = {
            "aws:PrincipalArn" : [
              "arn:aws:iam::*:role/OrganizationAccountAccessRole",
              "arn:aws:iam::*:role/IAMAdminRole"
            ]
          }
        }
      },
      {
        Sid    = "ProtectCloudTrail"
        Effect = "Deny"
        Action = [
          "cloudtrail:DeleteTrail",
          "cloudtrail:StopLogging",
          "cloudtrail:UpdateTrail"
        ]
        Resource = "*"
      },
      {
        Sid    = "ProtectConfig"
        Effect = "Deny"
        Action = [
          "config:DeleteConfigRule",
          "config:DeleteConfigurationRecorder",
          "config:DeleteDeliveryChannel",
          "config:StopConfigurationRecorder"
        ]
        Resource = "*"
      }
    ]
  })

  target_ou_ids = local.all_ou_ids
  tags = {
    Purpose = "security"
  }
}

