# AWS Organizations Account Module

This Terraform module manages AWS Organizations accounts and automatically adds the account ID to a Terraform Cloud variable set.

## Features

- Creates an AWS Organizations member account
- Configures IAM user billing access
- Adds account tags
- Creates a Terraform Cloud variable with the account ID
- Configurable account deletion protection

## Usage

```hcl
module "security_account" {
  source = "./modules/account"

  name                       = "security"
  email                      = "security@example.com"
  parent_id                  = aws_organizations_organizational_unit.security.id
  iam_user_access_to_billing = "ALLOW"
  variable_set_id            = data.tfe_variable_set.aws.id
  
  tags = {
    Environment = "security"
  }

  prevent_destroy = true
}
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.0.0 |
| aws | >= 4.0.0 |
| tfe | >= 0.40.0 |

## Providers

| Name | Version |
|------|---------|
| aws | >= 4.0.0 |
| tfe | >= 0.40.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| name | The name of the account | `string` | n/a | yes |
| email | The email address of the account owner | `string` | n/a | yes |
| parent_id | The ID of the parent organizational unit | `string` | n/a | yes |
| iam_user_access_to_billing | If true, the IAM users have access to the billing information for this account | `string` | `"ALLOW"` | no |
| tags | Additional tags to apply to the account | `map(string)` | `{}` | no |
| prevent_destroy | If true, prevents the account from being destroyed | `bool` | `true` | no |
| variable_set_id | The ID of the Terraform Cloud variable set to store the account ID | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| account_id | The AWS account ID |
| arn | The ARN for this account | 