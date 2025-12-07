output "lxc_ip" { value = split("/", proxmox_lxc.lxc.network[0].ip)[0] }
output "lxc_id" { value = proxmox_lxc.lxc.vmid }