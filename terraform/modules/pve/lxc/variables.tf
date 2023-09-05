# ---------------------------------------------------------------------------------------------------------------------
# REQUIRED PARAMETERS
# You must provide a value for each of these parameters.
# ---------------------------------------------------------------------------------------------------------------------

variable "target_node" {
  description = "The name of the Proxmox node"
  type        = string
}

variable "hostname" {
  description = "The hostname of the LXC container"
  type        = string
}

variable "vmid" {
  description = "The VM ID of the LXC container"
  type        = number
}

variable "ostemplate" {
  description = "The OS template of the LXC container"
  type        = string
  default     = "nas:vztmpl/debian-12-standard_12.0-1_amd64.tar.zst"
}

variable "password" {
  description = "The root password of the LXC container"
  type        = string
  default     = ""
}

variable "unprivileged" {
  description = "Set unprivileged flag"
  type        = bool
  default     = true
}

variable "ostype" {
  description = "The OS type of the LXC container"
  type        = string
  default     = "debian"
}

variable "ssh_keys" {
  description = "The public SSH key(s) to add to the LXC container"
  type        = string
  default     = ""
}

variable "nameserver" {
  description = "The nameserver to configure for the LXC container"
  type        = string
  default     = "10.11.20.1"
}

variable "searchdomain" {
  description = "The searchdomain to configure for the LXC container"
  type        = string
  default     = "int.sbbh.cloud"
}

variable "onboot" {
  description = "Start LXC container on boot"
  type        = bool
  default     = false
}

variable "fs" {
  description = "The filesystem type of the LXC container"
  type        = string
  default     = "local-lvm"
}

variable "size" {
  description = "The filesystem size of the LXC container"
  type        = string
}

variable "cores" {
  description = "The number of CPU cores of the LXC container"
  type        = number
}

variable "memory" {
  description = "The amount of memory of the LXC container"
  type        = number
}

variable "swap" {
  description = "The amount of swap memory of the LXC container"
  type        = number
}

variable "ip" {
  description = "The IP address of the LXC container"
  type        = string
}

variable "gw" {
  description = "The gateway IP address of the LXC container"
  type        = string
  default     = "10.11.20.1"
}

variable "hwaddr" {
  description = "The MAC address of the LXC container"
  type        = string
  default     = ""
}

variable "firewall" {
  description = "Enable firewall for LXC container"
  type        = bool
  default     = true
}

variable "fuse" {
  description = "Enable FUSE for LXC container"
  type        = bool
  default     = false
}

variable "nesting" {
  description = "Enable nesting for LXC container"
  type        = bool
  default     = false
}

variable "mount" {
  description = "Enable mount types for LXC container"
  type        = string
  default     = ""
}

variable "mountpoint" {
  description = "Mount points on LXC container"
  type        = list(object({
    key       = string
    slot      = number
    storage   = string
    volume    = string
    mp        = string
    size      = string
  }))
  default     = null
}
