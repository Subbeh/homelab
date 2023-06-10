vlan_tag = 5
gateway  = "10.11.5.1"

vms = {
  bastion = {
    target_node = "pve-nuc-01"
    vmid = 100
    memory = 4096
    cores = 1
    disk_size = "50G"
    ip = "10.11.5.2"
    mac = "4a:60:bb:7f:81:db"
  }
}
