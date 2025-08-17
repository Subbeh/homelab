# These variables are defined here for schema validation and documentation purposes
# The actual values are provided by the global TFE variable set "aws-variables"

# TFE Configuration
variable "tfe_organization" {
  description = "The name of the Terraform Cloud organization"
  type        = string
}

# AWS Global Configuration Variables
variable "aws_region" {
  description = "The AWS region to create resources in"
  type        = string
}

variable "aws_security_account_id" {
  description = "The security AWS account ID"
  type        = string
}
