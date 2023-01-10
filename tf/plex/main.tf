resource "proxmox_lxc" "plex" {
  target_node  = "pve-nuc"
  hostname     = "plex"
  vmid         = 110
  ostemplate   = "nas:vztmpl/ubuntu-22.04-standard_22.04-1_amd64.tar.zst"
  unprivileged = false
  ostype       = "ubuntu"

  ssh_public_keys = data.http.github-keys.response_body
  password = var.pm_vm_root_passwd

  rootfs {
    storage = "ext"
    size    = "20G"
  }

  cores = 2
  memory = "4096"
  swap = 0

  network {
      name     = "eth0"
      bridge   = "vmbr0"
      ip       = "10.0.10.40/24"
      gw       = "10.0.10.1"
      firewall = true
  }
}
