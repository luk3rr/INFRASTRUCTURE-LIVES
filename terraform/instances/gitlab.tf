module "gitlab" {
  source = "../modules/proxmox-lxc"

  hostname   = "gitlab"
  ip_address = "192.168.1.101"
  vm_id      = 101

  pve_node_name  = var.pve_node_name
  template_name  = var.debian_12_template
  ip_gateway     = var.default_gateway
  nameserver     = var.default_nameserver
  password       = var.default_lxc_password
  ssh_public_key = var.ssh_public_key

  cpu_cores = 4
  memory    = 12288
  disk_size = 64
  swap      = 4096
}