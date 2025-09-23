locals {
  homeassistant_url      = "https://github.com/home-assistant/operating-system/releases/download/${var.homeassistant_version}/haos_ova-${var.homeassistant_version}.qcow2.xz"
  homeassistant_filename = "haos_ova-${var.homeassistant_version}.qcow2.xz"
}

resource "null_resource" "download_homeassistant" {
  connection {
    type     = "ssh"
    host     = var.proxmox_host
    user     = var.proxmox_ssh_user
    password = var.proxmox_ssh_password
    # Use private_key instead of password for SSH connections
    # private_key = file(var.proxmox_ssh_private_key) # Read the private key file content
  }

  provisioner "remote-exec" {
    inline = [
      "mkdir -p /tmp/homeassistant",
      "cd /tmp/homeassistant",
      "[ ! -f '${local.homeassistant_filename}' ] && curl -L -o '${local.homeassistant_filename}' '${local.homeassistant_url}' || true ",
      "xz -k -d '${local.homeassistant_filename}'",
      "qemu-img convert -f qcow2 -O raw 'haos_ova-${var.homeassistant_version}.qcow2' 'haos_ova-${var.homeassistant_version}.raw'",
      "rm -rf 'haos_ova-${var.homeassistant_version}.qcow2'",
      "mv 'haos_ova-${var.homeassistant_version}.raw' '/var/lib/vz/images/'",
      # "rm -rf /tmp/homeassistant"
    ]
  }

  triggers = {
    version = var.homeassistant_version
  }
}

resource "proxmox_vm_qemu" "homeassistant" {
  depends_on = [null_resource.download_homeassistant]

  vmid        = 333
  name        = "homeassistant-test"
  target_node = var.proxmox_default_target_node
  clone       = null
  full_clone  = false

  # VM Configuration
  cpu {
    cores   = 2
    sockets = 1
    type    = "host"
  }

  memory  = 4096
  balloon = 2048

  # OS and Boot Configuration
  os_type = "other"
  bios    = "ovmf"
  machine = "q35"
  scsihw  = "virtio-scsi-pci"

  # Boot configuration
  agent    = 0 # QEMU guest agent not available in Home Assistant OS
  onboot   = true
  startup  = "order=1"
  vm_state = "stopped"

  # Network configuration
  network {
    id     = 0
    model  = "virtio"
    bridge = "vmbr0"
  }

  # Skip IPv6
  ipconfig0 = "ip=dhcp"

  # Console settings
  serial {
    id   = 0
    type = "socket"
  }

  # Disk configuration - define a disk for the VM
  disks {
    scsi {
      scsi0 {
        disk {
          backup     = false
          cache      = "none"
          discard    = true
          emulatessd = true
          iothread   = true
          replicate  = true
          size       = 32
          storage    = var.proxmox_default_storage
        }
      }
    }
  }

  # EFI disk for UEFI boot
  efidisk {
    efitype = "4m"
    storage = var.proxmox_default_storage
  }


  # Lifecycle management
  lifecycle {
    ignore_changes = [
      network,
      disks, # we're going to manage the disk ourselves
      vm_state
    ]
  }
}

# Import the Home Assistant disk image after VM creation
resource "null_resource" "import_disk" {
  depends_on = [proxmox_vm_qemu.homeassistant]

  connection {
    type     = "ssh"
    host     = var.proxmox_host
    user     = var.proxmox_ssh_user
    password = var.proxmox_ssh_password
    # Use private_key instead of password for SSH connections
    # private_key = file(var.proxmox_ssh_private_key) # Read the private key file content
  }

  provisioner "remote-exec" {
    inline = [
      "qm importdisk ${proxmox_vm_qemu.homeassistant.vmid} '/var/lib/vz/images/haos_ova-${var.homeassistant_version}.raw' ${var.proxmox_default_storage} --format raw",
      "qm set ${proxmox_vm_qemu.homeassistant.vmid} --scsi0 ${var.proxmox_default_storage}:vm-${proxmox_vm_qemu.homeassistant.vmid}-disk-1,cache=writethrough,ssd=1",
      "qm set ${proxmox_vm_qemu.homeassistant.vmid} --boot order=scsi0",
      "qm start ${proxmox_vm_qemu.homeassistant.vmid}"
    ]
  }

  triggers = {
    vm_id = proxmox_vm_qemu.homeassistant.vmid
  }
}
