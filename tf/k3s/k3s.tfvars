pm_host = "10.0.10.11"
gateway = "10.0.80.1"
vlan_tag = 80
vm_template = "ubuntu-2204-cloudinit-template"
storage = "local-lvm"

k3s_nodes = {
  # masters
  master_1 = {
    name = "k3s-master-1"
    target_node = "pve-nuc-01"
    ip = "10.0.80.11"
    cores = 4
    memory = 8192
    disk_size = "50G"
    id = 811
  }
  master_2 = {
    name = "k3s-master-2"
    target_node = "pve-opti-01"
    ip = "10.0.80.12"
    cores = 3
    memory = 8192
    disk_size = "50G"
    id = 812
  }
  master_3 = {
    name = "k3s-master-3"
    target_node = "pve-opti-02"
    ip = "10.0.80.13"
    cores = 2
    memory = 6144
    disk_size = "50G"
    id = 813
  }

  # workers
  worker_1 = {
    name = "k3s-worker-1"
    target_node = "pve-nuc-01"
    ip = "10.0.80.21"
    cores = 4
    memory = 22528
    disk_size = "50G"
    id = 821
  }
  worker_2 = {
    name = "k3s-worker-2"
    target_node = "pve-opti-01"
    ip = "10.0.80.22"
    cores = 3
    memory = 22528
    disk_size = "50G"
    id = 822
  }
  worker_3 = {
    name = "k3s-worker-3"
    target_node = "pve-opti-02"
    ip = "10.0.80.23"
    cores = 2
    memory = 8192
    disk_size = "50G"
    id = 823
  }
}
