variable "name" {
  description = "The name of the account"
  type        = string
}

variable "email" {
  description = "The email address of the account owner"
  type        = string
}

variable "parent_id" {
  description = "The ID of the parent organizational unit"
  type        = string
}

variable "iam_user_access_to_billing" {
  description = "If true, the IAM users have access to the billing information for this account"
  type        = string
  default     = "ALLOW"
}

variable "tags" {
  description = "Additional tags to apply to the account"
  type        = map(string)
  default     = {}
}
