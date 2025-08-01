module "kubernetes_node" {
  source = "../modules/proxmox-vm"

  vm_name       = "k8s-node"
  template_name = "ubuntu-2404-cloud-template"
  ip_address    = "192.168.1.100"
  vm_id         = 100
  memory        = 6144

  pve_node_name  = var.pve_node_name
  ip_gateway     = var.default_gateway
  nameserver     = var.default_nameserver
  ssh_public_key = var.ssh_public_key
}