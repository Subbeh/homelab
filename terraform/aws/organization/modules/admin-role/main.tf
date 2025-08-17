# Create a new administrator role
resource "aws_iam_role" "admin" {
  name               = "IAMAdminRole"
  assume_role_policy = var.trust_policy_json

  tags = {
    Purpose     = "cross-account-administration"
    ManagedBy   = "terraform"
  }
}

# Attach administrator access policy
resource "aws_iam_role_policy_attachment" "admin" {
  role       = aws_iam_role.admin.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# Outputs
output "role_arn" {
  description = "ARN of the administrator role"
  value       = aws_iam_role.admin.arn
}

output "role_name" {
  description = "Name of the administrator role"
  value       = aws_iam_role.admin.name
} 