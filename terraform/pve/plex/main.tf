module "lxc_container" {
  source = "../../modules/pve/lxc"

  target_node = "pve-nuc-01"
  hostname = "plex-test"
  vmid = 110

  size = "8G"
  cores = 2
  memory = 1024
  swap = 0

  ip = "10.11.20.40/24"

  fuse = true
  nesting = true
  mount = "nfs"

  extra_config = <<-EOT
    lxc.cgroup2.devices.allow: c 226:0 rwm
    lxc.cgroup2.devices.allow: c 226:128 rwm
    lxc.cgroup2.devices.allow: c 29:0 rwm
    lxc.mount.entry: /dev/fb0 dev/fb0 none bind,optional,create=file
    lxc.mount.entry: /dev/dri dev/dri none bind,optional,create=dir
    lxc.mount.entry: /dev/dri/renderD128 dev/renderD128 none bind,optional,create=file
    EOT
}
