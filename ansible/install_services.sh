#!/usr/bin/env bash

# =================================================================================
# ORQUESTRADOR DE INSTALAÇÃO DE SERVIÇOS COM ANSIBLE
# =================================================================================

set -e

source "$BASH_BEAUTIFUL"

PLAYBOOKS_DIR="playbooks"

SERVICE_PLAYBOOKS=(
  "adguard"
  "npm"
)

# =================================================================================
# MENU PRINCIPAL
# =================================================================================
msg_title "Service Installation Orchestrator"
PS3="Choose an installation option: "
options=("Install a Specific Service" "Install ALL Services" "Exit")

select opt in "${options[@]}"; do
  case $opt in
    "Install a Specific Service")
      msg_alert "Select the service you want to install:"

      select target_service in "${SERVICE_PLAYBOOKS[@]}"; do
        if [[ -n "$target_service" ]]; then
          msg_info "Starting installation of '${target_service}'..."
          ansible-playbook "${PLAYBOOKS_DIR}/${target_service}.yml" --ask-vault-pass
          msg_succ "Installation of '${target_service}' completed."
          break
        else
          msg_error "Invalid selection."
        fi
      done
      break
      ;;

    "Install ALL Services")
      msg_alert "You are about to install ALL services: ${SERVICE_PLAYBOOKS[*]}"
      read -p "Do you confirm this operation? (y/n): " confirm
      if [[ "$confirm" =~ ^[Yy]$ ]]; then
        for service in "${SERVICE_PLAYBOOKS[@]}"; do
          msg_title "Starting installation of '${service}'"
          ansible-playbook "${PLAYBOOKS_DIR}/${service}.yml" --ask-vault-pass
          msg_succ "Installation of '${service}' completed."
        done
        msg_succ "All services installed successfully!"
      else
        msg_error "Operation cancelled."
      fi
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
