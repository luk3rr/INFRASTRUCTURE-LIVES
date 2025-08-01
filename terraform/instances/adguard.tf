module "adguard" {
  source = "../modules/proxmox-lxc"

  hostname   = "adguard"
  ip_address = "192.168.1.102"
  vm_id      = 102

  pve_node_name  = var.pve_node_name
  template_name  = var.debian_12_template
  ip_gateway     = var.default_gateway
  password       = var.default_lxc_password
  ssh_public_key = var.ssh_public_key
  nameserver     = var.default_gateway
}
