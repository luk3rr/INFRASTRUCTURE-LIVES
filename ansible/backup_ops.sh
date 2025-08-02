#!/usr/bin/env bash

# =================================================================================
# ANSIBLE OPERATIONS ORCHESTRATOR
#
# Manages Backup, List, and Restore operations interactively.
# =================================================================================

set -e

source "$BASH_BEAUTIFUL"

# Ensures the SSH server is stopped upon completion.
cleanup() {
  msg_alert "Finalizing operation..."
  if systemctl is-active --quiet ssh; then
    msg_info "Stopping local SSH service..."
    sudo systemctl stop ssh
    msg_succ "Local SSH server stopped successfully."
  fi
}

# Ensures the 'cleanup' function is executed when the script finishes.
trap 'cleanup' EXIT

prepare_ssh_server() {
  msg_info "Checking if the SSH server (openssh-server) is installed..."
  if ! command -v sshd &> /dev/null; then
      msg_alert "SSH server not found. Installing..."
      sudo apt-get update && sudo apt-get install -y openssh-server
      msg_succ "SSH server installed successfully."
  else
      msg_succ "SSH server is already installed."
  fi

  msg_info "Starting local SSH server temporarily..."
  sudo systemctl start ssh
  msg_succ "SSH server is active."
}

get_backup_hosts() {
  awk '/^\[(lxc_containers|vms)\]/{f=1;next} /^\[/{f=0} f && !/^\s*($|#)/{print $1}' inventory.ini
}

# =================================================================================
# MAIN MENU
# =================================================================================

msg_title "Ansible Backup & Restore Orchestrator"
PS3="Choose an operation (enter the number): "
options=("Backup All Services" "List Snapshots for a Service" "Restore a Service" "Exit")

select opt in "${options[@]}"; do
  case $opt in
    "Backup All Services")
      prepare_ssh_server
      msg_alert "Starting full backup of all services..."
      ansible-playbook playbooks/backup.yml --ask-vault-pass
      msg_succ "Backup playbook completed."
      break
      ;;

    "List Snapshots for a Service")
      msg_alert "Select the service to list snapshots for:"

      hosts=($(get_backup_hosts))

      select target_host in "${hosts[@]}"; do
        if [[ -n "$target_host" ]]; then
          prepare_ssh_server
          msg_info "Fetching snapshots for '${target_host}'..."
          ansible-playbook playbooks/list-snapshots.yml -e "target_host=${target_host}" --ask-vault-pass
          break
        else
          msg_error "Invalid selection."
        fi
      done
      break
      ;;

    "Restore a Service")
      msg_alert "Select the service you want to restore:"

      hosts=($(get_backup_hosts))
      select target_host in "${hosts[@]}"; do
        if [[ -n "$target_host" ]]; then
          prepare_ssh_server

          msg_info "Fetching available snapshots for '${target_host}'..."
          ansible-playbook playbooks/list-snapshots.yml -e "target_host=${target_host}" --ask-vault-pass

          msg_alert "Now, provide the details for the restoration:"
          read -p "Paste the Snapshot ID you want to restore (or type 'latest'): " snapshot_id
          read -p "Enter the destination path in the container (e.g., /tmp/restore_npm): " restore_path

          echo ""
          msg_alert "WARNING: You are about to restore snapshot '${snapshot_id}' of '${target_host}' to the directory '${restore_path}'."
          read -p "Do you confirm this operation? (y/n): " confirm
          if [[ "$confirm" =~ ^[Yy]$ ]]; then
            msg_info "Starting restore..."
            ansible-playbook playbooks/restore-snapshots.yml \
              -e "target_host=${target_host}" \
              -e "snapshot_id=${snapshot_id}" \
              -e "restore_path=${restore_path}" \
              --ask-vault-pass
            msg_succ "Restore completed. Check the files in '${restore_path}' on host '${target_host}'."
          else
            msg_error "Restore operation cancelled."
          fi
          break
        else
          msg_error "Invalid selection."
        fi
      done
      break
      ;;

    "Exit")
      break
      ;;
    *)
      msg_error "Invalid option: $REPLY"
      ;;
  esac
done
