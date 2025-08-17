variable "tfe_organization" {
  description = "The name of the Terraform Cloud organization"
  type        = string
}

variable "tfe_project_id" {
  description = "TFC Project ID"
  type        = string
}

variable "tfe_workspaces" {
  description = "List of workspaces to create"
  type = list(object({
    name                  = string
    working_directory     = string
    execution_mode        = optional(string)
    auto_apply            = optional(bool)
    global_remote_state   = optional(bool)
    file_triggers_enabled = optional(bool)
    queue_all_runs        = optional(bool)
    terraform_cli_args    = optional(string)
  }))
}
