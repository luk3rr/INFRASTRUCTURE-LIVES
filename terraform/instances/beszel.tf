module "beszel" {
  source = "../modules/proxmox-lxc"

  hostname   = "beszel"
  ip_address = "192.168.1.111"
  vm_id      = 111

  pve_node_name  = var.pve_node_name
  template_name  = var.debian_12_template
  ip_gateway     = var.default_gateway
  nameserver     = var.default_nameserver
  password       = var.default_lxc_password
  ssh_public_key = var.ssh_public_key
}
