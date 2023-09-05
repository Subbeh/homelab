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

locals {
  hwaddr = coalesce(var.hwaddr, "e6:2b:f2:4f:${replace(format("%04x", var.vmid),"/(.{2})(.{2})/","$${1}:$${2}")}")
  network_name = "eth0"
  bridge = "vmbr0"
  tag = 20
}

resource "terraform_data" "pve_config" {
  connection {
    type     = "ssh"
    user     = "root"
    password = module.env.pm_password
    host     = var.target_node
  }

  provisioner "file" {
    content     = templatefile("${path.module}/lxc.conf.tftpl", {
      cores     = var.cores
      fuse      = var.fuse ? 1 : 0
      mount     = var.mount
      nesting   = var.nesting ? 1 : 0
      hostname  = var.hostname
      memory    = var.memory
      network_name = local.network_name
      bridge    = local.bridge
      firewall  = var.firewall ? 1 : 0
      hwaddr    = local.hwaddr
      ip        = var.ip
      tag       = local.tag
      onboot    = var.onboot ? 1 : 0
      ostype    = var.ostype
      fs        = var.fs
      vmid      = var.vmid
      size      = var.size
      swap      = var.swap
      config    = var.extra_config
    })
    destination = "/etc/pve/lxc/${var.vmid}.conf"
  }

  depends_on = [
    proxmox_lxc.this
  ]
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
    name     = local.network_name
    bridge   = local.bridge
    tag      = local.tag
    ip       = var.ip
    gw       = var.gw
    hwaddr   = var.hwaddr
    firewall = var.firewall
  }
}
