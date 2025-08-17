# Create AWS variable set
resource "tfe_variable_set" "aws" {
  name         = "aws-variables"
  description  = "AWS variables for all workspaces"
  organization = var.tfe_organization
  global       = true
}

# Add variables to AWS set
locals {
  account_configs = {
    security = {
      alias     = "security"
      workspace = "aws-security-account"
      id        = module.security_account.account_id
    }
    sandbox = {
      alias     = "sandbox"
      workspace = "aws-sandbox-account"
      id        = module.sandbox_account.account_id
    }
    production = {
      alias     = "production"
      workspace = "aws-prod-account"
      id        = module.production_account.account_id
    }
  }
}

resource "tfe_variable" "aws_region" {
  key             = "aws_region"
  value           = var.aws_region
  category        = "terraform"
  description     = "Primary AWS region"
  variable_set_id = tfe_variable_set.aws.id
}

resource "tfe_variable" "account_ids" {
  for_each = local.account_configs

  key             = "aws_${each.key}_account_id"
  value           = each.value.id
  category        = "terraform"
  description     = "${title(each.key)} AWS Account ID"
  variable_set_id = tfe_variable_set.aws.id
}

# Create OIDC provider and role in each account using the module
module "tfc_oidc_security" {
  source = "./modules/tfc-oidc"

  providers = {
    aws = aws.security
  }

  tfe_organization = var.tfe_organization
  tfe_project      = var.tfe_project
  workspace_name   = local.account_configs.security.workspace
}

module "tfc_oidc_sandbox" {
  source = "./modules/tfc-oidc"

  providers = {
    aws = aws.sandbox
  }

  tfe_organization = var.tfe_organization
  tfe_project      = var.tfe_project
  workspace_name   = local.account_configs.sandbox.workspace
}

module "tfc_oidc_production" {
  source = "./modules/tfc-oidc"

  providers = {
    aws = aws.production
  }

  tfe_organization = var.tfe_organization
  tfe_project      = var.tfe_project
  workspace_name   = local.account_configs.production.workspace
}

# Update TFE workspace variables
resource "tfe_variable" "enable_aws_provider_auth" {
  for_each = local.account_configs

  workspace_id = data.tfe_workspace.workspaces[each.value.workspace].id
  key          = "TFC_AWS_PROVIDER_AUTH"
  value        = "true"
  category     = "env"
  description  = "Enable the Workload Identity integration for AWS."
}

resource "tfe_variable" "tfc_aws_role_arn" {
  for_each = local.account_configs

  workspace_id = data.tfe_workspace.workspaces[each.value.workspace].id
  key          = "TFC_AWS_RUN_ROLE_ARN"
  value        = local.role_arns[each.key]
  category     = "env"
  description  = "The AWS role arn runs will use to authenticate."
}

locals {
  role_arns = {
    security   = module.tfc_oidc_security.role_arn
    sandbox    = module.tfc_oidc_sandbox.role_arn
    production = module.tfc_oidc_production.role_arn
  }
}

# Data source for workspaces
data "tfe_workspace" "workspaces" {
  for_each     = toset([for cfg in local.account_configs : cfg.workspace])
  name         = each.key
  organization = var.tfe_organization
}
