terraform {
  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "2.9.0"
    }
    http = {
      source  = "hashicorp/http"
      version = "3.4.0"
    }
  }
}

module "env" {
  source = "../../env"
}

data "http" "ssh_keys" {
  url = module.env.ssh_keys_url
}

resource "proxmox_lxc" "this" {
  target_node  = var.target_node
  hostname     = var.hostname
  vmid         = var.vmid
  ostemplate   = var.ostemplate
  password     = coalesce(var.password, module.env.pm_vm_password)
  unprivileged = var.unprivileged
  ostype       = var.ostype
  ssh_public_keys = coalesce(var.ssh_keys, data.http.ssh_keys.response_body)
  nameserver   = var.nameserver
  searchdomain = var.searchdomain
  onboot       = var.onboot

  cores = var.cores
  memory = var.memory
  swap = var.swap

  features {
    fuse = var.fuse
    nesting = var.nesting
    mount = var.mount
  }

  rootfs {
    storage = var.fs
    size    = var.size
  }

  network {
    name     = "eth0"
    bridge   = var.bridge
    tag      = var.tag
    ip       = var.ip
    gw       = var.gw
    hwaddr   = coalesce(var.hwaddr, "e6:2b:f2:4f:${replace(format("%04x", var.vmid),"/(.{2})(.{2})/","$${1}:$${2}")}")
    firewall = var.firewall
  }
}
