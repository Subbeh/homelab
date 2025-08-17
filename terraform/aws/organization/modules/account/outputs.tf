output "account_id" {
  description = "The AWS account ID"
  value       = aws_organizations_account.account.id
}

output "arn" {
  description = "The ARN for this account"
  value       = aws_organizations_account.account.arn
} 