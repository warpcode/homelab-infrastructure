resource "proxmox_lxc" "fileserver_lxc" {
  depends_on  = [null_resource.download_lxc_template]
  target_node = var.proxmox_default_target_node

  vmid       = var.fileserver_lxc_vmid
  hostname   = "fileserver-lxc"
  ostemplate = local.proxmox_default_lxc_container_template

  # Basic container configuration
  unprivileged    = true
  start           = true
  onboot          = true
  memory          = 1024
  swap            = 512
  cores           = 1
  password        = var.proxmox_default_lxc_password
  ssh_public_keys = var.proxmox_default_lxc_ssh_public_key

  rootfs {
    storage = var.proxmox_default_storage
    size    = var.proxmox_default_lxc_storage_size
  }

  network {
    name   = "eth0"
    bridge = "vmbr0"
    ip     = "${var.proxmox_default_ip_prefix}22/${var.proxmox_default_cidr}"
    gw     = var.proxmox_default_gateway
    ip6    = var.proxmox_default_lxc_ipv6_type
  }

  mountpoint {
    key     = 0
    slot    = 0
    mp      = "/storage/ebooks"
    storage = "${var.fileserver_storage_prefix}/ebooks"
    volume  = "${var.fileserver_storage_prefix}/ebooks"
    backup  = false
  }

  mountpoint {
    key     = 1
    slot    = 1
    mp      = "/storage/emulation"
    storage = "${var.fileserver_storage_prefix}/emulation"
    volume  = "${var.fileserver_storage_prefix}/emulation"
    backup  = false
  }

  mountpoint {
    key     = 2
    slot    = 2
    mp      = "/storage/tmp"
    storage = "${var.fileserver_storage_prefix}/tmp"
    volume  = "${var.fileserver_storage_prefix}/tmp"
    backup  = false
  }

  lifecycle {
    ignore_changes = [
      ostemplate,
    ]
  }
}
