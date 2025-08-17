# AWS Organizations Service Control Policy (SCP) Module

This module creates and manages Service Control Policies (SCPs) in AWS Organizations. It provides a standardized way to create SCPs and attach them to organizational units.

## Features

- Creates a single SCP with specified policy content
- Attaches the SCP to multiple organizational units
- Supports tagging for better resource management
- Standardized naming and documentation

## Usage

```hcl
module "region_lock_scp" {
  source = "./modules/scp"

  name           = "RegionLock"
  description    = "Restricts AWS operations to specific regions"
  policy_content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Deny"
        Action   = "*"
        Resource = "*"
        Condition = {
          StringNotEquals = {
            "aws:RequestedRegion": ["us-east-1"]
          }
        }
      }
    ]
  })

  target_ou_ids = [
    aws_organizations_organizational_unit.security.id,
    aws_organizations_organizational_unit.production.id
  ]

  tags = {
    Environment = "all"
    Purpose     = "region-restriction"
  }
}
```

## Requirements

- Terraform >= 1.5.7
- AWS Provider ~> 5.0
- AWS Organizations must be enabled
- IAM permissions to manage SCPs

## Inputs

| Name | Description | Type | Required |
|------|-------------|------|----------|
| name | The name of the SCP | string | yes |
| description | The description of the SCP | string | yes |
| policy_content | The JSON policy content for the SCP | string | yes |
| target_ou_ids | List of Organization Unit IDs to attach the SCP to | list(string) | yes |
| tags | Additional tags to apply to the SCP | map(string) | no |

## Outputs

| Name | Description |
|------|-------------|
| policy_id | The ID of the created SCP |
| policy_arn | The ARN of the created SCP |

## Best Practices

1. Policy Content:
   - Use clear, descriptive policy statements
   - Include comments for complex conditions
   - Follow least privilege principle
   - Test policies before applying

2. Naming Convention:
   - Use descriptive names that indicate policy purpose
   - Include policy type in name (e.g., RegionLock, MFARequired)
   - Keep names consistent across organization

3. Documentation:
   - Document policy purpose and effects
   - Include examples of allowed/denied actions
   - Note any exceptions or conditions

4. Tagging:
   - Tag policies for easier management
   - Include purpose and scope in tags
   - Use consistent tagging scheme

## Example Policies

### Region Lock
```hcl
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
            "aws:RequestedRegion": var.allowed_regions
          }
        }
      }
    ]
  })
  target_ou_ids = var.all_ou_ids
}
```

### MFA Requirement
```hcl
module "require_mfa" {
  source = "./modules/scp"

  name        = "RequireMFA"
  description = "Requires MFA for all non-service users"
  policy_content = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Deny"
        Action = "*"
        Resource = "*"
        Condition = {
          BoolIfExists = {
            "aws:MultiFactorAuthPresent": "false"
          }
        }
      }
    ]
  })
  target_ou_ids = var.all_ou_ids
}
``` 