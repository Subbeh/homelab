resource "proxmox_vm_qemu" "bastion" {
  name        = "bastion"
  target_node = "pve-nuc-01"
  os_type     = "cloud-init"
  full_clone  = true
  vmid        = 100
  memory      = 4096
  sockets     = 1
  cores       = 2
  cpu         = "host"
  scsihw      = "virtio-scsi-pci"
  clone       = "ubuntu-2204-cloudinit-template"
  agent       = 1

  disk {
    size    = "30G"
    type    = "scsi"
    storage = "local-lvm"
  }

  network {
    model = "virtio"
    bridge = "vmbr0"
    tag = 5
    macaddr = "4a:60:bb:7f:81:db"
  }

  # Cloud-init section
  ipconfig0 = "ip=10.11.5.2/30,gw=10.11.5.1"
  sshkeys = <<EOF
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILh7KPCVrDEoX2T0+Wv/qX3yZlFlMBfHq4IeL9CsC4rS sysadm@home
sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIHbKExSh6uhGschahin7Kz2Bti3M/549IE55VxwgTCqXAAAACXNzaDprZXktMQ== yubikey-01-res
sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIK0V4Dyzam6vvHG1aaU5cteAlf8BJrvf8mfMCFQdGYzMAAAACXNzaDprZXktMg== yubikey-02-res
sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIOWFy10d1pWh4EOmIGhyycy0Mwab75hIFrDSYfDEl+xZAAAACXNzaDprZXktNQ== yubikey-05-res
EOF

  # lifecycle {
  #   ignore_changes = [
  #     ciuser,
  #     sshkeys,
  #     disk,
  #     network
  #   ]
  # }
}


data "sops_file" "bastion_secrets" {
  source_file = "bastion.sops.yaml"
}
