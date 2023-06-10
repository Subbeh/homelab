variable "vms" {
  description = "vm variables in a dictionary "
  type        = map(any)
}
variable "pm_host" {
  type    = string
  default = "10.11.10.21"
}
variable "vm_template" {
  type    = string
  default = "ubuntu-2204-cloudinit-template"
}
variable "gateway" {
  type    = string
  default = "10.11.20.1"
}
variable "vlan_tag" {
  type    = number
  default = 20
}
variable "storage" {
  type    = string
  default = "local-lvm"
}
variable "nameserver" {
  type    = string
  default = "10.11.20.1"
}
variable "searchdomain" {
  type    = string
  default = "int.sbbh.cloud"
}
variable "sshkeys" {
  type    = string
  default = <<EOF
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILh7KPCVrDEoX2T0+Wv/qX3yZlFlMBfHq4IeL9CsC4rS sysadm@home
sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIHbKExSh6uhGschahin7Kz2Bti3M/549IE55VxwgTCqXAAAACXNzaDprZXktMQ== yubikey-01-res
sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIK0V4Dyzam6vvHG1aaU5cteAlf8BJrvf8mfMCFQdGYzMAAAACXNzaDprZXktMg== yubikey-02-res
sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIOWFy10d1pWh4EOmIGhyycy0Mwab75hIFrDSYfDEl+xZAAAACXNzaDprZXktNQ== yubikey-05-res
EOF
}
