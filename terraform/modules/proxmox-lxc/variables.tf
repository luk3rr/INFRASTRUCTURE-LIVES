variable "hostname" {
  type = string
}

variable "vm_id" {
  type = number
}

variable "pve_node_name" {
  type = string
}

variable "template_name" {
  type = string
}

variable "password" {
  type      = string
  sensitive = true
}

variable "ssh_public_key" {
  type      = string
  sensitive = true
}

variable "memory" {
  type    = number
  default = 512
}

variable "swap" {
  type    = number
  default = 512
}

variable "cpu_cores" {
  type    = number
  default = 1
}

variable "disk_size" {
  type    = number
  default = 4
}

variable "disk_storage" {
  type    = string
  default = "local-lvm"
}

variable "network_bridge" {
  type    = string
  default = "vmbr0"
}

variable "ip_address" {
  type = string
}

variable "ip_cidr" {
  type    = number
  default = 24
}

variable "ip_gateway" {
  type = string
}

variable "nameserver" {
  type = string
}

variable "start_on_create" {
  type    = bool
  default = true
}

variable "start_on_boot" {
  type    = bool
  default = true
}
