variable "k3s_nodes" {
  description = "vm variables in a dictionary "
  type        = map(any)
}

variable "pm_host" {}
variable "vm_template" {}
variable "gateway" {}
variable "vlan_tag" {}
variable "storage" {}
