# AWS Organization Admin Role Module

This module creates a new administrator role (IAMAdminRole) that can be assumed by specified principals. It's used for cross-account access in an AWS Organization structure.

## Features

- Creates a dedicated administrator role for cross-account access
- Attaches the AWS managed AdministratorAccess policy
- Configurable trust policy for role assumption
- Proper tagging for management and tracking

## Requirements

- Terraform >= 1.5.7
- AWS Provider ~> 5.0
- AWS provider configured for the target account
- IAM permissions to create roles and attach policies

## Usage

```hcl
provider "aws" {
  alias  = "target_account"
  region = "us-east-1"
  assume_role {
    role_arn = "arn:aws:iam::ACCOUNT_ID:role/OrganizationAccountAccessRole"
  }
}

module "account_admin_role" {
  source = "../modules/organization/admin-role"
  providers = {
    aws = aws.target_account
  }
  trust_policy_json = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::ACCOUNT_ID:user/USERNAME"
        }
        Action = "sts:AssumeRole"
        Condition = {
          Bool = {
            "aws:MultiFactorAuthPresent": "true"
          }
        }
      }
    ]
  })
}
```

## Providers

| Name | Version |
|------|---------|
| aws | ~> 5.0 |

## Inputs

| Name | Description | Type | Required |
|------|-------------|------|----------|
| trust_policy_json | JSON policy document that controls which principals can assume this role | string | yes |

## Outputs

| Name | Description |
|------|-------------|
| role_arn | ARN of the administrator role |
| role_name | Name of the administrator role |

## Security Considerations

- The role has full administrator access
- MFA enforcement should be implemented in the trust policy
- Role is dedicated for cross-account administration
- Proper tagging for tracking and management 