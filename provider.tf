# Configure the KeePass provider
provider "keepass" {
  database = pathexpand(var.keepass_database_path)
  password = var.keepass_database_password
}

# REMOVED: Data source to fetch Proxmox API credentials from KeePass
# data "keepass_entry" "proxmox_credentials" {
#   path = "Root/intranet/Pve1" # Changed from 'title' to 'path' as required
# }


provider "proxmox" {
  # Configuration options
  pm_api_url = var.proxmox_api_url
  pm_user    = var.proxmox_api_user
  # Use proxmox_api_password from main.auto.tfvars
  pm_password = var.proxmox_api_password
  # pm_api_token_id     = var.proxmox_api_token_id
  # pm_api_token_secret = var.proxmox_api_token_secret
  pm_tls_insecure = var.proxmox_api_tls_insecure
  pm_parallel     = 2
  pm_timeout      = 1200
}
