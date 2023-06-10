resource "proxmox_vm_qemu" "vms" {
  for_each    = var.vms
  name        = each.key
  target_node = each.value.target_node
  os_type     = "cloud-init"
  clone       = var.vm_template
  full_clone  = true
  vmid        = each.value.vmid
  agent       = 1

  memory      = each.value.memory
  sockets     = "1"
  cores       = each.value.cores
  cpu         = "host"
  scsihw      = "virtio-scsi-pci"

  nameserver  = var.nameserver
  searchdomain = var.searchdomain
  sshkeys     = var.sshkeys

  disk {
    size    = each.value.disk_size
    type    = "scsi"
    storage = var.storage
  }

  network {
    model = "virtio"
    bridge = "vmbr0"
    tag = var.vlan_tag
    macaddr = each.value.mac
  }

  ipconfig0 = "ip=${each.value.ip}/24,gw=${var.gateway}"
}
