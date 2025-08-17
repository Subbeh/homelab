terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      configuration_aliases = [aws]
    }
  }
}

variable "tfe_organization" {
  description = "The name of the Terraform Cloud organization"
  type        = string
}

variable "tfe_project" {
  description = "The name of the Terraform Cloud project"
  type        = string
}

variable "workspace_name" {
  description = "The name of the Terraform Cloud workspace"
  type        = string
}

variable "tls_certificate_url" {
  description = "The URL of the TLS certificate"
  type        = string
  default     = "https://app.terraform.io"
}

# Create OIDC provider
resource "aws_iam_openid_connect_provider" "tfc_provider" {
  url             = var.tls_certificate_url
  client_id_list  = ["aws.workload.identity"]
  thumbprint_list = [data.tls_certificate.tfc_certificate.certificates[0].sha1_fingerprint]
}

# Create IAM role
resource "aws_iam_role" "tfc_role" {
  name = "tfc-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.tfc_provider.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "app.terraform.io:aud" = "aws.workload.identity"
          }
          StringLike = {
            "app.terraform.io:sub" = "organization:${var.tfe_organization}:project:${var.tfe_project}:workspace:${var.workspace_name}:run_phase:*"
          }
        }
      }
    ]
  })
}

# Attach AdministratorAccess policy
resource "aws_iam_role_policy_attachment" "tfc_policy_attachment" {
  role       = aws_iam_role.tfc_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

data "tls_certificate" "tfc_certificate" {
  url = var.tls_certificate_url
}

output "role_arn" {
  description = "The ARN of the created IAM role"
  value       = aws_iam_role.tfc_role.arn
} 