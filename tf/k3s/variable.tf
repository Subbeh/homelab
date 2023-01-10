variable "pm_node_name" {
  description = "name of the proxmox node to create the VMs on"
  type        = string
  default     = "pve"
}

variable "k3s_masters" {
  description = "vm variables in a dictionary "
  type        = map(any)
}

variable "k3s_workers" {
  description = "vm variables in a dictionary "
  type        = map(any)
}

variable "template_vm_name" {}

variable "networkrange" {
  default = 24
}

variable "gateway" {
  default = "10.0.10.1"
}

variable "storage" {}
