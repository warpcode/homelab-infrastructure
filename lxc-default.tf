locals {
  proxmox_default_lxc_container_template = "${var.proxmox_default_lxc_storage}:vztmpl/${var.proxmox_default_lxc_template}"
}

resource "null_resource" "download_lxc_template" {
  connection {
    type     = "ssh"
    host     = var.proxmox_host
    user     = var.proxmox_ssh_user
    password = var.proxmox_ssh_password
  }

  provisioner "remote-exec" {
    inline = [
      "pveam update",
      "pveam list ${var.proxmox_default_lxc_storage} | awk '{print $1}' | grep -qFx \"${local.proxmox_default_lxc_container_template}\" || pveam download ${var.proxmox_default_lxc_storage} ${var.proxmox_default_lxc_template}"
    ]
  }

  triggers = {
    lxc_container_template = var.proxmox_default_lxc_template
  }
}
