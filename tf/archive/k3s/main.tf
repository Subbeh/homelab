resource "proxmox_vm_qemu" "pve_k3s_nodes" {
  for_each    = var.k3s_nodes
  name        = each.value.name
  desc        = each.value.name
  target_node = each.value.target_node
  os_type     = "cloud-init"
  full_clone  = true
  vmid        = each.value.id
  memory      = each.value.memory
  sockets     = "1"
  cores       = each.value.cores
  cpu         = "host"
  scsihw      = "virtio-scsi-pci"
  clone       = var.vm_template
  agent       = 1

  disk {
    size    = each.value.disk_size
    type    = "scsi"
    storage = var.storage
  }

  # Setup the network interface and assign a vlan tag: 256
  network {
    model = "virtio"
    bridge = "vmbr0"
    tag = var.vlan_tag
  }

  # Cloud-init section
  ipconfig0 = "ip=${each.value.ip}/24,gw=${var.gateway}"

  lifecycle {
    ignore_changes = [
      ciuser,
      sshkeys,
      disk,
      network
    ]
  }
}

variable "k3s_nodes" {
  description = "vm variables in a dictionary "
  type        = map(any)
}
