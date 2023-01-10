terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "2.9.0"
    }
  }
  required_version = ">= 0.13"
}

provider "proxmox" {
  pm_api_url          = "https://${var.pm_host}:8006/api2/json"
  pm_api_token_id     = var.pm_api_token_id
  pm_api_token_secret = var.pm_api_token_secret
  pm_tls_insecure     = var.pm_tls_insecure
  pm_parallel         = 2
  pm_timeout          = 600
  pm_debug            = true
  pm_log_enable       = true
  pm_log_file         = "terraform-plugin-proxmox.log"
  pm_log_levels = {
    _default          = "debug"
    _capturelog       = ""
  }
}

data "http" "github-keys" {
  url = "https://raw.githubusercontent.com/Subbeh/dotfiles/master/keys"
}

variable "pm_host" {
  description = "The hostname or IP of the Proxmox server"
  type        = string
}

variable "pm_api_token_id" {
  description = "Proxmox API Token ID"
  type        = string
  sensitive   = false
  default     = "terraform@pve"
}

variable "pm_api_token_secret" {
  description = "Proxmox API Token Secret"
  type        = string
  sensitive   = true
}

variable "pm_tls_insecure" {
  description = "Set to true to ignore certificate errors"
  type        = bool
  default     = true
}

variable "pm_vm_root_passwd" {
  description = "Set the root password for the VM/CT"
  type        = string
  sensitive   = true
}
