#!/usr/bin/env bash

# =================================================================================
# ORQUESTRADOR DE INSTALAÇÃO DE SERVIÇOS COM ANSIBLE
# =================================================================================

set -e

source "$BASH_BEAUTIFUL"

PLAYBOOKS_DIR="playbooks"

# Service : Parameters
SERVICE_PLAYBOOKS=(
  "gitlab:--ask-vault-pass"
  "adguard:--ask-vault-pass"
  "npm:"
  "kuma:"
  "heimdall:"
  "vault:"
  "kubernetes:"
  "postgres:--ask-vault-pass"
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

      service_names=()
      for entry in "${SERVICE_PLAYBOOKS[@]}"; do
        service_name="${entry%%:*}"
        service_names+=("$service_name")
      done

      select target_service in "${service_names[@]}"; do
        if [[ -n "$target_service" ]]; then
          for entry in "${SERVICE_PLAYBOOKS[@]}"; do
            name="${entry%%:*}"
            params="${entry#*:}"
            if [[ "$name" == "$target_service" ]]; then
              msg_info "Starting installation of '${name}'..."
              ansible-playbook "${PLAYBOOKS_DIR}/${name}.yml" $params
              msg_succ "Installation of '${name}' completed."
              break
            fi
          done
          break
        else
          msg_error "Invalid selection."
        fi
      done
      break
      ;;

    "Install ALL Services")
      msg_alert "You are about to install ALL services:"
      for entry in "${SERVICE_PLAYBOOKS[@]}"; do
        echo "  - ${entry%%:*}"
      done
      read -p "Do you confirm this operation? (y/n): " confirm

      if [[ "$confirm" =~ ^[Yy]$ ]]; then
        for entry in "${SERVICE_PLAYBOOKS[@]}"; do
          name="${entry%%:*}"
          params="${entry#*:}"
          msg_title "Starting installation of '${name}'"
          ansible-playbook "${PLAYBOOKS_DIR}/${name}.yml" $params
          msg_succ "Installation of '${name}' completed."
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
