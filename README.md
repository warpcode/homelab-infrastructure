# Homelab Infrastructure
Infrastructure-as-code to stand up LXC containers and VMs on Proxmox.

## Table of Contents
- Overview
- Prerequisites
- Providers / Plugins
- What Gets Deployed
- Configuration
- Usage
- Make Targets
- Proxmox Host Requirements
- Security Notes
- Troubleshooting

## Overview
Goal: allow quick rebuild and management of homelab infra for disaster recovery using Terraform.

## Prerequisites
- Terraform

## Providers / Plugins
- `telmate/proxmox`
- `hashicorp/null`

## What Gets Deployed
- LXC container for Docker
  - Resource: `proxmox_lxc.docker_lxc`
  - VMID: `100`, hostname: `docker-lxc`
  - This container is designed to host Docker applications, with necessary features enabled for containerization.
- LXC container for Fileserver
  - Resource: `proxmox_lxc.fileserver_lxc`
  - VMID: `101`, hostname: `fileserver-lxc`
  - This container is configured as a network fileserver with specific mount points for media and temporary storage.
- Home Assistant VM on Proxmox
  - Resources: `null_resource.download_homeassistant`, `proxmox_vm_qemu.homeassistant`, `null_resource.import_disk`
  - VMID: `333`, hostname: `homeassistant-test`
  - This VM is configured to run Home Assistant OS, with automatic download and import of the specified version.

## Configuration
Key variables (see `vars.tf` for full list and defaults):
- Proxmox API: `proxmox_api_url`, `proxmox_api_user`, `proxmox_api_password`, `proxmox_api_tls_insecure`
- Proxmox target/storage: `proxmox_default_target_node`, `proxmox_default_storage`, `proxmox_default_iso_storage`, `proxmox_default_lxc_storage`, `proxmox_default_lxc_storage_size`
- LXC template: `proxmox_default_lxc_template`
- Network: `proxmox_default_ip_prefix`, `proxmox_default_cidr`, `proxmox_default_gateway`
- SSH: `proxmox_host`, `proxmox_ssh_user`, `proxmox_ssh_password`
- Home Assistant: `homeassistant_version`

Provide sensitive values via environment (`TF_VAR_*`) or a local `*.auto.tfvars` ignored by git.

## Variables

| Name | Type | Default | Sensitive | Description |
| --- | --- | --- | --- | --- |
| `proxmox_host` | string | `"192.168.1.20"` | no | Proxmox server hostname/IP (for SSH connection) |
| `proxmox_ssh_user` | string | `"root"` | no | SSH username for Proxmox server |
| `proxmox_ssh_password` | string | n/a | yes | SSH password for Proxmox server (consider using SSH keys instead) |
| `proxmox_api_url` | string | `"https://192.168.1.20:8006/api2/json"` | no | Proxmox API URL |
| `proxmox_api_user` | string | `"root@pam"` | no | Proxmox API user |
| `proxmox_api_password` | string | n/a | yes | Proxmox API password |
| `proxmox_api_tls_insecure` | bool | n/a | no | Skip TLS verification |
| `proxmox_default_target_node` | string | `"pve1"` | no | Proxmox node to connect to |
| `proxmox_default_storage` | string | `"local-lvm"` | no | Storage location for VM |
| `proxmox_default_iso_storage` | string | `"local"` | no | Storage location for ISO files |
| `proxmox_default_ip_prefix` | string | `"192.168.1."` | no | Default IP address prefix (first three octets) |
| `proxmox_default_cidr` | number | `24` | no | Default CIDR value for network configuration |
| `proxmox_default_gateway` | string | `"192.168.1.1"` | no | Default gateway IP address for network configuration |
| `proxmox_default_target_node` | string | `"pve1"` | no | Proxmox node to connect to |
| `proxmox_default_storage` | string | `"local-lvm"` | no | Storage location for VM |
| `proxmox_default_iso_storage` | string | `"local"` | no | Storage location for ISO files |
| `proxmox_default_lxc_storage` | string | `"local"` | no | Proxmox default lxc container image |
| `proxmox_default_lxc_template` | string | `"debian-12-standard_12.12-1_amd64.tar.zst"` | no | Proxmox default lxc container image |
| `proxmox_default_lxc_storage_size` | string | `"8G"` | no | Default storage size for LXC containers |
| `homeassistant_version` | string | `"16.0"` | no | Home Assistant version to download |

## Usage
Initialize and validate:

```bash
terraform init
make check
```

Plan and apply:

```bash
terraform plan
terraform apply
```

## Make Targets
- `check`: run `terraform fmt` and `terraform validate`

## Proxmox Host Requirements
Ensure these tools are available (used by remote-exec):
- `pveam`, `curl`, `xz`, `qemu-img`, `qm`

Ensure storage names referenced by variables exist (e.g., `local`, `local-lvm`).

## Security Notes
- Do not commit any secrets. Use environment variables or a local `.auto.tfvars` excluded from VCS.
- Consider using API tokens instead of passwords for Proxmox.
- Set `proxmox_api_tls_insecure` appropriately for your environment.

## Troubleshooting
- If LXC template download fails, verify `proxmox_default_lxc_template` and storage exist in Proxmox (`pveam available`).
- If Home Assistant import fails, verify free space on the Proxmox node and that `qemu-img` and `qm` are present.
- For SSH issues, confirm Proxmox host/user credentials and network reachability.
