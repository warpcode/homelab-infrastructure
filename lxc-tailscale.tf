locals {
  tailscale_config_file = "/etc/pve/lxc/${var.tailscale_lxc_vmid}.conf"
  cgroup_devices_line   = "lxc.cgroup2.devices.allow: c 10:200 rwm"
  tun_mount_line        = "lxc.mount.entry: /dev/net/tun dev/net/tun none bind,create=file"
}

resource "proxmox_lxc" "tailscale_lxc" {
  depends_on  = [null_resource.download_lxc_template]
  target_node = var.proxmox_default_target_node

  vmid       = var.tailscale_lxc_vmid
  hostname   = "tailscale"
  ostemplate = local.proxmox_default_lxc_container_template

  password     = var.proxmox_default_lxc_password
  unprivileged = false
  start        = true

  cores  = 1
  memory = 512

  ssh_public_keys = var.proxmox_default_lxc_ssh_public_key

  rootfs {
    storage = var.proxmox_default_storage
    size    = var.proxmox_default_lxc_storage_size
  }

  network {
    name   = "eth0"
    bridge = "vmbr0"
    ip     = "${var.proxmox_default_ip_prefix}35/${var.proxmox_default_cidr}"
    gw     = var.proxmox_default_gateway
  }

  lifecycle {
    ignore_changes = [
      ostemplate,
    ]
  }
}

# This null_resource appends custom LXC configuration lines to allow TUN device access for Tailscale,
# then restarts the container to apply the changes. It runs when the LXC is created or when manually tainted.
resource "null_resource" "tailscale_lxc_config" {
  depends_on = [proxmox_lxc.tailscale_lxc]

  provisioner "remote-exec" {
    connection {
      type     = "ssh"
      host     = var.proxmox_host
      user     = var.proxmox_ssh_user
      password = var.proxmox_ssh_password
    }

    inline = [
      "grep -Fxq '${local.cgroup_devices_line}' ${local.tailscale_config_file} || echo '${local.cgroup_devices_line}' >> ${local.tailscale_config_file}",
      "grep -Fxq '${local.tun_mount_line}' ${local.tailscale_config_file} || echo '${local.tun_mount_line}' >> ${local.tailscale_config_file}",
      "pct stop ${var.tailscale_lxc_vmid} || true; pct start ${var.tailscale_lxc_vmid}"
    ]
  }
}
