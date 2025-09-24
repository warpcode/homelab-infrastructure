resource "proxmox_lxc" "fileserver_lxc" {
  depends_on  = [null_resource.download_lxc_template]
  target_node = var.proxmox_default_target_node

  vmid       = 101 # Choose a unique VMID, e.g., 101
  hostname   = "fileserver-lxc"
  ostemplate = local.proxmox_default_lxc_container_template

  # Basic container configuration
  unprivileged = true
  start        = true
  onboot       = true
  memory       = 1024
  swap         = 512
  cores        = 1
  password     = "password123"

  rootfs {
    storage = var.proxmox_default_storage
    size    = var.proxmox_default_lxc_storage_size
  }

  network {
    name   = "eth0"
    bridge = "vmbr0"
    ip     = "${var.proxmox_default_ip_prefix}22/${var.proxmox_default_cidr}"
    gw     = var.proxmox_default_gateway
    ip6    = "dhcp"
  }

  mountpoint {
    key     = 0
    slot    = 0
    mp      = "/storage/ebooks"
    storage = "/storage/ebooks" # Path on the Proxmox host
    volume  = "/storage/ebooks"
    backup  = false
  }

  mountpoint {
    key     = 1
    slot    = 1
    mp      = "/storage/emulation"
    storage = "/storage/emulation" # Path on the Proxmox host
    volume  = "/storage/emulation"
    backup  = false
  }

  mountpoint {
    key     = 2
    slot    = 2
    mp      = "/storage/tmp"
    storage = "/storage/tmp" # Path on the Proxmox host
    volume  = "/storage/tmp"
    backup  = false
  }

  lifecycle {
    ignore_changes = [
      ostemplate,
    ]
  }
}
