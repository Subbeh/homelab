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

variable "aws_production_account_id" {
  description = "The production AWS account ID"
  type        = string
}

# Resume
variable "domain_name" {
  description = "Domain name"
  type        = string
}

variable "resume_subdomain" {
  description = "The subdomain for the resume website"
  type        = string
}

variable "resume_bucket" {
  description = "The S3 bucket name for the resume website"
  type        = string
}

# CloudFlare
variable "CLOUDFLARE_API_TOKEN" {
  description = "CloudFlare API token for DNS management"
  type        = string
  sensitive   = true
}
