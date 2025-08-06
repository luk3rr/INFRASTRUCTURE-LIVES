resource "proxmox_vm_qemu" "vm" {
  name        = var.vm_name
  vmid        = var.vm_id
  target_node = var.pve_node_name
  clone       = var.template_name
  onboot      = var.onboot
  memory      = var.memory
  os_type     = "cloud-init"
  scsihw      = "virtio-scsi-pci"
  agent       = 1

  cpu {
    cores = var.cpu_cores
  }

  disk {
    backup  = true
    format  = "raw"
    size    = "${var.disk_size}G"
    storage = var.disk_storage
    type    = "disk"
    slot    = "scsi0"
    discard = true
  }

  disk {
    backup  = true
    format  = "raw"
    type    = "cloudinit"
    storage = var.disk_storage
    slot    = "ide2"
  }

  serial {
    id   = 0
    type = "socket"
  }

  network {
    bridge = var.network_bridge
    model  = "virtio"
    id     = 0
  }

  ipconfig0  = "ip=${var.ip_address}/${var.ip_cidr},gw=${var.ip_gateway}"
  nameserver = var.nameserver
  sshkeys    = var.ssh_public_key
}
