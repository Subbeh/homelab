data "aws_ssoadmin_instances" "sso_instance" {}

resource "aws_ssoadmin_permission_set" "admin_access" {
  name             = "AdministratorAccess"
  instance_arn     = var.aws_sso_instance_arn
  session_duration = "PT12H"
}

# Attach AWS managed AdministratorAccess policy to the permission set
resource "aws_ssoadmin_managed_policy_attachment" "admin_policy" {
  instance_arn       = var.aws_sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.admin_access.arn
  managed_policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_identitystore_user" "admin" {
  identity_store_id = tolist(data.aws_ssoadmin_instances.sso_instance.identity_store_ids)[0]

  display_name = "Systems Administrator"
  user_name    = var.aws_admin_user

  name {
    given_name  = "Steven"
    family_name = "Terwindt"
  }

  emails {
    value = var.aws_admin_user_email
  }
}

# Assign admin access to security account
resource "aws_ssoadmin_account_assignment" "admin_security" {
  instance_arn       = var.aws_sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.admin_access.arn

  principal_id   = aws_identitystore_user.admin.user_id
  principal_type = "USER"

  target_id   = module.security_account.account_id
  target_type = "AWS_ACCOUNT"
}

# Assign admin access to production account
resource "aws_ssoadmin_account_assignment" "admin_production" {
  instance_arn       = var.aws_sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.admin_access.arn

  principal_id   = aws_identitystore_user.admin.user_id
  principal_type = "USER"

  target_id   = module.production_account.account_id
  target_type = "AWS_ACCOUNT"
}

# Assign admin access to sandbox account
resource "aws_ssoadmin_account_assignment" "admin_sandbox" {
  instance_arn       = var.aws_sso_instance_arn
  permission_set_arn = aws_ssoadmin_permission_set.admin_access.arn

  principal_id   = aws_identitystore_user.admin.user_id
  principal_type = "USER"

  target_id   = module.sandbox_account.account_id
  target_type = "AWS_ACCOUNT"
}

# Output the SSO login URL
output "sso_login_url" {
  description = "The URL to access the AWS SSO login portal"
  value       = "https://${tolist(data.aws_ssoadmin_instances.sso_instance.identity_store_ids)[0]}.awsapps.com/start"
}

