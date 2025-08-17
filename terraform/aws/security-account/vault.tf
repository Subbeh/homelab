# KMS key for Vault auto-unseal
resource "aws_kms_key" "vault_unseal" {
  description             = "KMS key for Hashicorp Vault auto-unseal"
  deletion_window_in_days = 7
  enable_key_rotation     = true

  # Key policy to allow the root account and the Vault IAM user to use the key
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "Enable IAM User Permissions"
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${var.aws_security_account_id}:root"
        }
        Action   = "kms:*"
        Resource = "*"
      },
      {
        Sid    = "Allow Vault to use the key"
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_user.vault.arn
        }
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:DescribeKey"
        ]
        Resource = "*"
      }
    ]
  })

  tags = {
    Name        = "vault-unseal-key"
    Environment = "security"
    Service     = "vault"
    Purpose     = "auto-unseal"
  }
}

# KMS alias for easier identification
resource "aws_kms_alias" "vault_unseal" {
  name          = "alias/vault-unseal"
  target_key_id = aws_kms_key.vault_unseal.key_id
}

# IAM user for Vault
resource "aws_iam_user" "vault" {
  name = "vault-unseal"
  path = "/service/"

  tags = {
    Name        = "vault-unseal"
    Environment = "security"
    Service     = "vault"
    Purpose     = "auto-unseal"
  }
}

# Create access key for Vault user
resource "aws_iam_access_key" "vault" {
  user = aws_iam_user.vault.name
}

# IAM policy for Vault to use KMS
resource "aws_iam_user_policy" "vault_kms" {
  name = "vault-kms-unseal"
  user = aws_iam_user.vault.name

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "kms:Encrypt",
          "kms:Decrypt",
          "kms:DescribeKey"
        ]
        Resource = [
          aws_kms_key.vault_unseal.arn
        ]
      }
    ]
  })
}

# Output the KMS key ARN and alias
output "vault_kms_key_arn" {
  description = "ARN of the KMS key used for Vault auto-unseal"
  value       = aws_kms_key.vault_unseal.arn
}

output "vault_kms_key_alias" {
  description = "Alias of the KMS key used for Vault auto-unseal"
  value       = aws_kms_alias.vault_unseal.name
}

output "vault_iam_user_arn" {
  description = "ARN of the IAM user created for Vault auto-unseal"
  value       = aws_iam_user.vault.arn
}

output "vault_aws_region" {
  description = "AWS Region"
  value       = var.aws_region
}

# Output the access key details (sensitive)
output "vault_access_key_id" {
  description = "Access key ID for the Vault user"
  value       = aws_iam_access_key.vault.id
  sensitive   = true
}

output "vault_secret_key" {
  description = "Secret access key for the Vault user"
  value       = aws_iam_access_key.vault.secret
  sensitive   = true
}

