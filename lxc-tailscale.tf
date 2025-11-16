locals {
  tailscale_config_file              = "/etc/pve/lxc/${var.tailscale_lxc_vmid}.conf"
  tailscale_cgroup_devices_line      = "lxc.cgroup2.devices.allow: c 10:200 rwm"
  tailscale_tun_mount_line           = "lxc.mount.entry: /dev/net/tun dev/net/tun none bind,create=file"
  tailscale_sysctl_ipv4_forward      = "net.ipv4.ip_forward = 1"
  tailscale_sysctl_ipv6_forward      = "net.ipv6.conf.all.forwarding = 1"
  tailscale_sysctl_ipv4_source_route = "net.ipv4.conf.all.accept_source_route = 1"
  tailscale_sysctl_ipv6_source_route = "net.ipv6.conf.all.accept_source_route = 1"
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

# This null_resource configures the Tailscale LXC container by:
# - Appending TUN device access lines to the LXC config (idempotent)
# - Restarting the container to apply changes
# - Waiting for the container to be ready for commands
# - Configuring sysctl for IP forwarding (idempotent)
# - Installing curl if not present (idempotent)
# - Installing Tailscale inside the container if not already present (idempotent)
# It runs when the LXC is created or when manually tainted.
resource "null_resource" "tailscale_lxc_config" {
  depends_on = [proxmox_lxc.tailscale_lxc]

  # triggers = {
  #   always_run = timestamp()
  # }

  provisioner "remote-exec" {
    connection {
      type     = "ssh"
      host     = var.proxmox_host
      user     = var.proxmox_ssh_user
      password = var.proxmox_ssh_password
    }

    inline = [
      "grep -Fxq '${local.tailscale_cgroup_devices_line}' ${local.tailscale_config_file} || echo '${local.tailscale_cgroup_devices_line}' >> ${local.tailscale_config_file}",
      "grep -Fxq '${local.tailscale_tun_mount_line}' ${local.tailscale_config_file} || echo '${local.tailscale_tun_mount_line}' >> ${local.tailscale_config_file}",
      "pct stop ${var.tailscale_lxc_vmid} || true; pct start ${var.tailscale_lxc_vmid}",
      "while ! pct exec ${var.tailscale_lxc_vmid} -- echo 'ready' >/dev/null 2>&1; do sleep 1; done",
      "pct exec ${var.tailscale_lxc_vmid} -- bash -c 'grep -Fxq \"${local.tailscale_sysctl_ipv4_forward}\" /etc/sysctl.conf || echo \"${local.tailscale_sysctl_ipv4_forward}\" >> /etc/sysctl.conf'",
      "pct exec ${var.tailscale_lxc_vmid} -- bash -c 'grep -Fxq \"${local.tailscale_sysctl_ipv6_forward}\" /etc/sysctl.conf || echo \"${local.tailscale_sysctl_ipv6_forward}\" >> /etc/sysctl.conf'",
      "pct exec ${var.tailscale_lxc_vmid} -- bash -c 'grep -Fxq \"${local.tailscale_sysctl_ipv4_source_route}\" /etc/sysctl.conf || echo \"${local.tailscale_sysctl_ipv4_source_route}\" >> /etc/sysctl.conf'",
      "pct exec ${var.tailscale_lxc_vmid} -- bash -c 'grep -Fxq \"${local.tailscale_sysctl_ipv6_source_route}\" /etc/sysctl.conf || echo \"${local.tailscale_sysctl_ipv6_source_route}\" >> /etc/sysctl.conf'",
      "pct exec ${var.tailscale_lxc_vmid} -- bash -c 'sysctl -p /etc/sysctl.conf'",
      "pct exec ${var.tailscale_lxc_vmid} -- bash -c 'if ! command -v curl >/dev/null 2>&1; then apt update && apt install -y curl; fi'",
      "pct exec ${var.tailscale_lxc_vmid} -- bash -c 'if ! command -v tailscale >/dev/null 2>&1; then curl -fsSL https://tailscale.com/install.sh | sh && systemctl start tailscaled; fi'",
      "pct exec ${var.tailscale_lxc_vmid} -- tailscale set --accept-routes --advertise-exit-node --advertise-routes=192.168.1.0/24"
    ]
  }
}
