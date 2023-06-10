resource "proxmox_vm_qemu" "bastion" {
  name        = "services"
  target_node = "pve-nuc-01"
  os_type     = "cloud-init"
  full_clone  = true
  vmid        = 120
  memory      = 8192
  sockets     = 1
  cores       = 2
  cpu         = "host"
  scsihw      = "virtio-scsi-pci"
  clone       = "ubuntu-2204-cloudinit-template"
  agent       = 1

  disk {
    size    = "50G"
    type    = "scsi"
    storage = "local-lvm"
  }

  network {
    model = "virtio"
    bridge = "vmbr0"
    tag = 20
    macaddr = "c6:56:ec:28:aa:a6"
  }

  # Cloud-init section
  ipconfig0 = "ip=10.11.20.100/30,gw=10.11.20.1"
  sshkeys = <<EOF
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILh7KPCVrDEoX2T0+Wv/qX3yZlFlMBfHq4IeL9CsC4rS sysadm@home
sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIHbKExSh6uhGschahin7Kz2Bti3M/549IE55VxwgTCqXAAAACXNzaDprZXktMQ== yubikey-01-res
sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIK0V4Dyzam6vvHG1aaU5cteAlf8BJrvf8mfMCFQdGYzMAAAACXNzaDprZXktMg== yubikey-02-res
sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIOWFy10d1pWh4EOmIGhyycy0Mwab75hIFrDSYfDEl+xZAAAACXNzaDprZXktNQ== yubikey-05-res
EOF
}
