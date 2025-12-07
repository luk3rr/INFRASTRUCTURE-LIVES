resource "proxmox_lxc" "lxc" {
  target_node     = var.pve_node_name
  hostname        = var.hostname
  ostemplate      = var.template_name
  vmid            = var.vm_id
  cores           = var.cpu_cores
  memory          = var.memory
  swap            = var.swap
  password        = var.password
  ssh_public_keys = var.ssh_public_key
  start           = var.start_on_create
  onboot          = var.start_on_boot
  nameserver      = var.nameserver

  rootfs {
    storage = var.disk_storage
    size    = "${var.disk_size}G"
  }

  network {
    name   = "eth0"
    bridge = var.network_bridge
    ip     = "${var.ip_address}/${var.ip_cidr}"
    gw     = var.ip_gateway
  }
}
