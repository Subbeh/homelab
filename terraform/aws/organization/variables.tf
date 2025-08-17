# TFE Configuration
variable "tfe_organization" {
  description = "The name of the Terraform Cloud organization"
  type        = string
}

variable "tfe_project" {
  description = "The name of the Terraform Cloud project"
  type        = string
}

# AWS Global Configuration Variables
variable "aws_region" {
  description = "The AWS region to create resources in"
  type        = string
}

variable "aws_additional_regions" {
  description = "Additional AWS regions allowed for resource deployment"
  type        = list(string)
}

variable "aws_sso_instance_arn" {
  description = "ARN of the AWS SSO instance"
  type        = string
}

variable "aws_security_account_email" {
  description = "Email address for the security account"
  type        = string
}

variable "aws_production_account_email" {
  description = "Email address for the production account"
  type        = string
}

variable "aws_sandbox_account_email" {
  description = "Email address for the sandbox account"
  type        = string
}

variable "aws_admin_user" {
  description = "Username for the AWS administrator"
  type        = string
}

variable "aws_admin_user_email" {
  description = "Email for the AWS administrator"
  type        = string
}

variable "aws_monthly_budget_amount" {
  description = "The monthly budget amount in USD for the organization"
  type        = number
}

variable "tfe_workspaces" {
  description = "List of Terraform Cloud workspaces that can assume the AWS role"
  type        = list(string)
  default     = [
    "aws-security-account",
    "aws-sandbox-account",
    "aws-prod-account"
  ]
}
