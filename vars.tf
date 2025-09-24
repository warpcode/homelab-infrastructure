# =============================================================================
# Proxmox Config
# =============================================================================

variable "proxmox_host" {
  description = "Proxmox server hostname/IP (for SSH connection)"
  type        = string
  default     = "192.168.1.20"
}

variable "proxmox_ssh_user" {
  description = "SSH username for Proxmox server"
  type        = string
  default     = "root"
}

variable "proxmox_ssh_password" {
  description = "SSH password for Proxmox server (consider using SSH keys instead)"
  type        = string
  sensitive   = true
}

# variable "proxmox_ssh_private_key" {
#   description = "Path to SSH private key for Proxmox server"
#   type        = string
#   # default     = "" # REMOVED: Provide securely via TF_VAR or .tfvars
# }

variable "proxmox_api_url" {
  description = "Proxmox API URL."
  type        = string
  default     = "https://192.168.1.20:8006/api2/json"
}

variable "proxmox_api_user" {
  description = "Proxmox API user."
  type        = string
  default     = "root@pam"
}

variable "proxmox_api_password" {
  description = "Proxmox API password. If null, KeePass will be used."
  type        = string
  sensitive   = true
}

variable "proxmox_api_tls_insecure" {
  description = "Skip TLS verification"
  type        = bool
}

variable "proxmox_default_ip_prefix" {
  description = "Default IP address prefix (first three octets)"
  type        = string
  default     = "192.168.1."
}

variable "proxmox_default_cidr" {
  description = "Default CIDR value for network configuration"
  type        = number
  default     = 24
}

# variable "proxmox_api_token_id" {
#     type = string
# }
#
# variable "proxmox_api_token_secret" {
#     type = string
# }

variable "proxmox_default_target_node" {
  description = "Proxmox node to connect to"
  type        = string
  default     = "pve1"
}

variable "proxmox_default_storage" {
  description = "Storage location for VM"
  type        = string
  default     = "local-lvm"
}

variable "proxmox_default_iso_storage" {
  description = "Storage location for ISO files"
  type        = string
  default     = "local"
}

variable "proxmox_default_lxc_storage" {
  description = "Proxmox default lxc container image"
  type        = string
  default     = "local"
}

variable "proxmox_default_lxc_template" {
  description = "Proxmox default lxc container image"
  type        = string
  default     = "debian-12-standard_12.12-1_amd64.tar.zst"
}

# =============================================================================
# Home Assistant Config
# =============================================================================

variable "homeassistant_version" {
  description = "Home Assistant version to download"
  type        = string
  default     = "16.0"
}

## KeePass variables removed; secrets should be provided via environment or .tfvars
