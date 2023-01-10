resource "proxmox_vm_qemu" "pve_k3s_masters" {
  for_each    = var.k3s_masters
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
  clone       = var.template_vm_name
  agent       = 1
  disk {
    size    = each.value.disk_size
    type    = "scsi"
    storage = var.storage
  }

  # Cloud-init section
  ipconfig0 = "ip=${each.value.ip}/24,gw=${each.value.gw}"

  lifecycle {
    ignore_changes = [
      ciuser,
      sshkeys,
      disk,
      network
    ]
  }
}

resource "proxmox_vm_qemu" "pve_k3s_workers" {
  for_each    = var.k3s_workers
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
  clone       = var.template_vm_name
  agent       = 1
  disk {
    size    = each.value.disk_size
    type    = "scsi"
    storage = var.storage
  }

  # Cloud-init section
  ipconfig0 = "ip=${each.value.ip}/24,gw=${each.value.gw}"

  lifecycle {
    ignore_changes = [
      ciuser,
      sshkeys,
      disk,
      network
    ]
  }
}
