resource "proxmox_lxc" "docker_lxc" {
  depends_on  = [null_resource.download_lxc_template]
  target_node = var.proxmox_default_target_node

  vmid       = 100
  hostname   = "docker-lxc"
  ostemplate = local.proxmox_default_lxc_container_template

  password     = "password123"
  unprivileged = false
  start        = true

  cores  = 1
  memory = 2048

  features {
    fuse    = true
    nesting = true
    mount   = "nfs;cifs"
  }

  rootfs {
    storage = var.proxmox_default_storage
    size    = var.proxmox_default_lxc_storage_size
  }

  network {
    name   = "eth0"
    bridge = "vmbr0"
    ip     = "${var.proxmox_default_ip_prefix}33/${var.proxmox_default_cidr}"
    gw     = var.proxmox_default_gateway
    ip6    = "dhcp"
  }

  lifecycle {
    ignore_changes = [
      ostemplate,
    ]
  }
}
