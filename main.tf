terraform {
  required_version = ">=0.13.0"

  required_providers {
    proxmox = {
      source  = "telmate/proxmox"
      version = "3.0.2-rc03"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }
  }
}

