vlan_tag   = 80
gateway    = "10.11.80.1"
nameserver = "10.11.80.1"

vms = {
  # masters
  k3s-master-1 = {
    target_node = "pve-nuc-01"
    vmid = 811
    memory = 8192
    cores = 4
    disk_size = "50G"
    ip = "10.11.80.11"
    mac = "88:b2:c6:2e:63:11"
  }
  k3s-master-2 = {
    target_node = "pve-opti-01"
    vmid = 812
    memory = 8192
    cores = 3
    disk_size = "50G"
    ip = "10.11.80.12"
    mac = "88:b2:c6:2e:63:12"
  }
  k3s-master-3 = {
    target_node = "pve-opti-02"
    vmid = 813
    memory = 6144
    cores = 2
    disk_size = "50G"
    ip = "10.11.80.13"
    mac = "88:b2:c6:2e:63:13"
  }
  # workers
  k3s-worker-1 = {
    target_node = "pve-nuc-01"
    vmid = 821
    memory = 22528
    cores = 4
    disk_size = "50G"
    ip = "10.11.80.21"
    mac = "88:b2:c6:2e:63:21"
  }
  k3s-worker-2 = {
    target_node = "pve-opti-01"
    vmid = 822
    memory = 22528
    cores = 3
    disk_size = "50G"
    ip = "10.11.80.22"
    mac = "88:b2:c6:2e:63:22"
  }
  k3s-worker-3 = {
    target_node = "pve-opti-02"
    vmid = 823
    memory = 8192
    cores = 2
    disk_size = "50G"
    ip = "10.11.80.23"
    mac = "88:b2:c6:2e:63:23"
  }
}
