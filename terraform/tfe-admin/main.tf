terraform {
  required_providers {
    tfe = {
      source  = "hashicorp/tfe"
      version = "~> 0.68.0"
    }
  }
  required_version = "~> 1.13.0"

  cloud {
    organization = "sbbh-cloud"
    workspaces {
      name = "terraform-admin"
    }
  }
}

provider "tfe" {}

# Create TFE Workspaces
resource "tfe_workspace" "workspaces" {
  for_each = { for ws in var.tfe_workspaces : ws.name => ws }

  name                  = each.value.name
  organization          = var.tfe_organization
  project_id            = var.tfe_project_id
  working_directory     = each.value.working_directory
  allow_destroy_plan    = false
  auto_apply            = each.value.auto_apply != null ? each.value.auto_apply : false
  file_triggers_enabled = each.value.file_triggers_enabled != null ? each.value.file_triggers_enabled : true
  queue_all_runs        = each.value.queue_all_runs != null ? each.value.queue_all_runs : true
  terraform_version     = "~> 1.13.0"
}

# Set workspace settings
resource "tfe_workspace_settings" "workspace_settings" {
  for_each = { for ws in var.tfe_workspaces : ws.name => ws }

  workspace_id        = tfe_workspace.workspaces[each.key].id
  execution_mode      = each.value.execution_mode != null ? each.value.execution_mode : "remote"
  global_remote_state = each.value.global_remote_state != null ? each.value.global_remote_state : false
}

# Set CLI arguments for workspaces that need them
resource "tfe_variable" "cli_args" {
  for_each = {
    for ws in var.tfe_workspaces : ws.name => ws
    if ws.terraform_cli_args != null
  }

  workspace_id = tfe_workspace.workspaces[each.key].id
  category     = "env"
  key          = "TF_CLI_ARGS"
  value        = each.value.terraform_cli_args
  description  = "CLI arguments for terraform commands"
}

# Create TFE variable set
resource "tfe_variable_set" "tfe" {
  name         = "tfe-variables"
  description  = "global TFE variables"
  organization = var.tfe_organization
  global       = true
}

# Add TFE organization to global set
resource "tfe_variable" "tfe_organization" {
  key             = "tfe_organization"
  value           = var.tfe_organization
  category        = "terraform"
  description     = "TFE Organization name"
  variable_set_id = tfe_variable_set.tfe.id
}

# Output workspace IDs for use in other workspaces
output "workspace_ids" {
  value       = { for name, ws in tfe_workspace.workspaces : name => ws.id }
  description = "Map of workspace names to their IDs"
}
