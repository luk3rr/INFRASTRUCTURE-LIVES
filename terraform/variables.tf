variable "ssh_public_key" {
  type        = string
  description = "SSH public key to inject into VMs via cloud-init"
  sensitive   = true
}

variable "default_lxc_password" {
  type        = string
  description = "Default password for LXC containers"
  sensitive   = true
}

variable "proxmox_api_url" {
  type        = string
  description = "The full URL for the Proxmox API, including the port."
}

variable "pm_api_token_id" {
  type        = string
  description = "The ID of the Proxmox API token"
  sensitive   = true
}

variable "pm_api_token_secret" {
  type        = string
  description = "The secret of the Proxmox API token"
  sensitive   = true
}