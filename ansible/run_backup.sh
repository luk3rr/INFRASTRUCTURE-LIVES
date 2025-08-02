#!/usr/bin/env bash

# =================================================================================
# WRAPPER SCRIPT TO SECURELY EXECUTE THE ANSIBLE BACKUP
# =================================================================================

set -e

source "$BASH_BEAUTIFUL"

cleanup() {
  msg_alert "\nFinalizing the backup process..."
  if systemctl is-active --quiet ssh; then
    msg_info "Stopping local SSH service..."
    sudo systemctl stop ssh
    msg_succ "Local SSH server stopped successfully."
  else
    msg_info "Local SSH server was already stopped."
  fi
}

trap 'cleanup' EXIT

msg_title "Starting Centralized Backup Process"

msg_info "Checking if the SSH server (openssh-server) is installed..."
if ! command -v sshd &> /dev/null; then
    msg_alert "SSH server not found. Installing..."
    sudo apt-get update
    sudo apt-get install -y openssh-server
    msg_succ "SSH server (openssh-server) installed successfully."
else
    msg_succ "SSH server is already installed."
fi

msg_info "Starting local SSH server temporarily..."
sudo systemctl start ssh
msg_succ "SSH server is active."
echo ""

msg_alert "Running Ansible backup playbook... (This may take a few minutes)"
ansible-playbook playbooks/backup.yml --ask-vault-pass