locals {
  docker_config_file              = "/etc/pve/lxc/100.conf"
  docker_apparmor_line            = "lxc.apparmor.profile: unconfined"
  docker_devices_allow_line       = "lxc.cgroup2.devices.allow: a"
  docker_cap_drop_line            = "lxc.cap.drop:"
  docker_mount_auto_line          = "lxc.mount.auto: proc:rw sys:rw cgroup:rw"
  docker_sysctl_ipv4_forward      = "net.ipv4.ip_forward = 1"
  docker_sysctl_ipv6_forward      = "net.ipv6.conf.all.forwarding = 1"
  docker_sysctl_ipv4_source_route = "net.ipv4.conf.all.accept_source_route = 1"
  docker_sysctl_ipv6_source_route = "net.ipv6.conf.all.accept_source_route = 1"
}

resource "proxmox_lxc" "docker_lxc" {
  depends_on  = [null_resource.download_lxc_template]
  target_node = var.proxmox_default_target_node

  vmid       = 100
  hostname   = "docker-lxc"
  ostemplate = local.proxmox_default_lxc_container_template

  password     = var.proxmox_default_lxc_password
  unprivileged = false
  start        = true

  cores  = 4
  memory = 8192

  ssh_public_keys = var.proxmox_default_lxc_ssh_public_key

  features {
    fuse    = true
    nesting = true
    keyctl  = true
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
    ip6    = var.proxmox_default_lxc_ipv6_type
  }

  lifecycle {
    ignore_changes = [
      ostemplate,
    ]
  }
}

# This null_resource configures the Docker LXC container by:
# - Appending AppArmor profile line to the LXC config (idempotent)
# - Restarting the container to apply changes
# - Waiting for the container to be ready for commands
# - Configuring sysctl for IP forwarding (idempotent)
# - Installing Docker inside the container if not already present (idempotent)
# It runs when the LXC is created or when manually tainted.
resource "null_resource" "docker_lxc_config" {
  depends_on = [proxmox_lxc.docker_lxc]

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
      "grep -Fxq '${local.docker_apparmor_line}' ${local.docker_config_file} || echo '${local.docker_apparmor_line}' >> ${local.docker_config_file}",
      "grep -Fxq '${local.docker_devices_allow_line}' ${local.docker_config_file} || echo '${local.docker_devices_allow_line}' >> ${local.docker_config_file}",
      "grep -Fxq '${local.docker_cap_drop_line}' ${local.docker_config_file} || echo '${local.docker_cap_drop_line}' >> ${local.docker_config_file}",
      "grep -Fxq '${local.docker_mount_auto_line}' ${local.docker_config_file} || echo '${local.docker_mount_auto_line}' >> ${local.docker_config_file}",
      "pct set 100 -mp0 /storage/docker,mp=/var/lib/docker",
      "pct stop 100 || true; pct start 100",
      "while ! pct exec 100 -- echo 'ready' >/dev/null 2>&1; do sleep 1; done",
      "pct exec 100 -- bash -c 'grep -Fxq \"${local.docker_sysctl_ipv4_forward}\" /etc/sysctl.conf || echo \"${local.docker_sysctl_ipv4_forward}\" >> /etc/sysctl.conf'",
      "pct exec 100 -- bash -c 'grep -Fxq \"${local.docker_sysctl_ipv6_forward}\" /etc/sysctl.conf || echo \"${local.docker_sysctl_ipv6_forward}\" >> /etc/sysctl.conf'",
      "pct exec 100 -- bash -c 'grep -Fxq \"${local.docker_sysctl_ipv4_source_route}\" /etc/sysctl.conf || echo \"${local.docker_sysctl_ipv4_source_route}\" >> /etc/sysctl.conf'",
      "pct exec 100 -- bash -c 'grep -Fxq \"${local.docker_sysctl_ipv6_source_route}\" /etc/sysctl.conf || echo \"${local.docker_sysctl_ipv6_source_route}\" >> /etc/sysctl.conf'",
      "pct exec 100 -- bash -c 'sysctl -p /etc/sysctl.conf'",
      "pct exec 100 -- bash -c 'if ! command -v docker >/dev/null 2>&1; then apt update && apt install -y docker.io && systemctl start docker && systemctl enable docker; fi'"
    ]
  }
}
