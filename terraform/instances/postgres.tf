module "postgres" {
  source = "../modules/proxmox-lxc"

  hostname   = "postgres"
  ip_address = "192.168.1.109"
  vm_id      = 109

  pve_node_name  = var.pve_node_name
  template_name  = var.debian_12_template
  ip_gateway     = var.default_gateway
  nameserver     = var.default_nameserver
  password       = var.default_lxc_password
  ssh_public_key = var.ssh_public_key

  cpu_cores = 2
  memory    = 2048
  swap      = 2048
  disk_size = 20
}