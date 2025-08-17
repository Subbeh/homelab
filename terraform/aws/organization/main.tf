# Enable AWS Organizations
resource "aws_organizations_organization" "org" {
  aws_service_access_principals = [
    "cloudtrail.amazonaws.com",
    "config.amazonaws.com",
    "securityhub.amazonaws.com",
    "sso.amazonaws.com",
    "ram.amazonaws.com",
    "backup.amazonaws.com"
  ]

  feature_set = "ALL"

  enabled_policy_types = [
    "SERVICE_CONTROL_POLICY",
    "TAG_POLICY"
  ]
}

# Create Organizational Units
resource "aws_organizations_organizational_unit" "security" {
  name      = "Security"
  parent_id = aws_organizations_organization.org.roots[0].id
}

resource "aws_organizations_organizational_unit" "production" {
  name      = "Production"
  parent_id = aws_organizations_organization.org.roots[0].id
}

resource "aws_organizations_organizational_unit" "sandbox" {
  name      = "Sandbox"
  parent_id = aws_organizations_organization.org.roots[0].id
}

# Create member accounts using the account module
module "security_account" {
  source = "./modules/account"

  name                       = "security"
  email                      = var.aws_security_account_email
  parent_id                  = aws_organizations_organizational_unit.security.id
  iam_user_access_to_billing = "ALLOW"
}

module "production_account" {
  source = "./modules/account"

  name                       = "production"
  email                      = var.aws_production_account_email
  parent_id                  = aws_organizations_organizational_unit.production.id
  iam_user_access_to_billing = "ALLOW"
}

module "sandbox_account" {
  source = "./modules/account"

  name                       = "sandbox"
  email                      = var.aws_sandbox_account_email
  parent_id                  = aws_organizations_organizational_unit.sandbox.id
  iam_user_access_to_billing = "ALLOW"
}
