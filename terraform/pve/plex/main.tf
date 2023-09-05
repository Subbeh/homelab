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

  mountpoint = [
    {
      key = "0"
      slot = 0
      storage = "/dev/fb0"
      volume  = "/dev/fb0"
      mp      = "/dev/fb0"
      size    = "32G"
    },
    {
      key = "1"
      slot = 1
      storage = "/dev/dri"
      volume  = "/dev/dri"
      mp      = "/dev/dri"
      size    = "32G"
    },
    {
      key = "3"
      slot = 3
      storage = "/dev/dri/renderD128"
      volume  = "/dev/dri/renderD128"
      mp      = "/dev/dri/renderD128"
      size    = "32G"
    }
  ]
}
