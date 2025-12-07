variable "pve_node_name" {
  type        = string
  description = "The name of the Proxmox node where resources will be created."
  default     = "nexus"
}

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

variable "debian_12_template" {
  type        = string
  description = "Debian 12 template to use for LXC containers"
  default     = "local:vztmpl/debian-12-standard_12.7-1_amd64.tar.zst"
}

variable "default_gateway" {
  type        = string
  description = "Default gateway for the network"
  default     = "192.168.1.1"
}

variable "default_nameserver" {
  type        = string
  description = "Default nameserver for the network"
  default     = "192.168.1.102"
}