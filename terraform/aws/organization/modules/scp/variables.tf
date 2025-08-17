variable "name" {
  description = "The name of the SCP"
  type        = string
}

variable "description" {
  description = "The description of the SCP"
  type        = string
}

variable "policy_content" {
  description = "The JSON policy content for the SCP"
  type        = string
}

variable "target_ou_ids" {
  description = "List of Organization Unit IDs to attach the SCP to"
  type        = list(string)
}

variable "tags" {
  description = "Additional tags to apply to the SCP"
  type        = map(string)
  default     = {}
} 