module "sonarqube" {
  source = "../modules/proxmox-lxc"

  hostname   = "sonarqube"
  ip_address = "192.168.1.109"
  vm_id      = 109

  cpu_cores = 2
  memory    = 4096
  swap      = 4096
  disk_size = 15

  pve_node_name  = var.pve_node_name
  template_name  = var.debian_12_template
  ip_gateway     = var.default_gateway
  nameserver     = var.default_nameserver
  password       = var.default_lxc_password
  ssh_public_key = var.ssh_public_key
}