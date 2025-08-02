module "npm" {
  source = "../modules/proxmox-lxc"

  hostname   = "npm"
  ip_address = "192.168.1.103"
  vm_id      = 103

  pve_node_name  = var.pve_node_name
  template_name  = var.debian_12_template
  ip_gateway     = var.default_gateway
  nameserver     = var.default_gateway
  password       = var.default_lxc_password
  ssh_public_key = var.ssh_public_key

  disk_size = 4
}