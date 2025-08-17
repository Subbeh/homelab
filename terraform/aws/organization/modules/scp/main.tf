# SCP Policy resource
resource "aws_organizations_policy" "policy" {
  name        = var.name
  description = var.description
  content     = var.policy_content

  tags = merge(
    {
      "Name"        = var.name
      "Description" = var.description
      "ManagedBy"   = "terraform"
    },
    var.tags
  )
}

# Policy attachments to OUs
resource "aws_organizations_policy_attachment" "attachments" {
  for_each = toset(var.target_ou_ids)

  policy_id = aws_organizations_policy.policy.id
  target_id = each.value
}

# Outputs
output "policy_id" {
  description = "The ID of the created SCP"
  value       = aws_organizations_policy.policy.id
}

output "policy_arn" {
  description = "The ARN of the created SCP"
  value       = aws_organizations_policy.policy.arn
} 