module "infrastructure" {
  source               = "./instances"
  default_lxc_password = var.default_lxc_password
  ssh_public_key       = var.ssh_public_key
}
