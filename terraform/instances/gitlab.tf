module "gitlab" {
  source = "../modules/proxmox-vm"

  vm_name       = "gitlab"
  template_name = "ubuntu-2404-cloud-template"
  ip_address    = "192.168.1.101"
  vm_id         = 101

  pve_node_name  = var.pve_node_name
  ip_gateway     = var.default_gateway
  nameserver     = var.default_nameserver
  ssh_public_key = var.ssh_public_key

  cpu_cores = 4
  memory    = 12288
  disk_size = 64
}