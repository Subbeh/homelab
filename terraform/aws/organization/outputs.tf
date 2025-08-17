output "aws_security_account_id" {
  description = "The ID of the Security AWS account"
  value       = module.security_account.account_id
}

output "aws_sandbox_account_id" {
  description = "The ID of the Sandbox AWS account"
  value       = module.sandbox_account.account_id
}

output "aws_production_account_id" {
  description = "The ID of the Production AWS account"
  value       = module.production_account.account_id
}
