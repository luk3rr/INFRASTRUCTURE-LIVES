#!/usr/bin/env bash

# =================================================================================
# ORQUESTRADOR DE INSTALAÇÃO DE SERVIÇOS COM ANSIBLE
# =================================================================================

set -e

source "$BASH_BEAUTIFUL"

PLAYBOOKS_DIR="playbooks"
SECRETS_FILE="group_vars/secrets.yml"

# Service : Parameters
SERVICE_PLAYBOOKS=(
  "adguard:--ask-vault-pass:"
  "npm::"
  "kuma::"
  "heimdall::"
  "vault::"
  "postgres:--ask-vault-pass:"
  "kubernetes::"
  "gitlab:--ask-vault-pass:"
  "gitlab-runner:--ask-vault-pass:gitlab_runner_token"
)

check_and_set_secret() {
  local secret_key="$1"
  local prompt_message="$2"

  if [[ -z "$VAULT_PASS" ]]; then
    read -sp "Enter Ansible Vault password to check/edit secrets: " VAULT_PASS
    echo
  fi

  local secret_exists
  secret_exists=$(ansible-vault view "${SECRETS_FILE}" --vault-password-file <(printf "%s" "$VAULT_PASS") 2>/dev/null | grep "^${secret_key}:" || true)

  if [[ -z "$secret_exists" ]]; then
    msg_alert "The secret '${secret_key}' was not found in the Vault."
    read -p "${prompt_message}: " secret_value

    local temp_file
    temp_file=$(mktemp)
    ansible-vault decrypt "${SECRETS_FILE}" --vault-password-file <(printf "%s" "$VAULT_PASS") --output "${temp_file}" 2>/dev/null

    printf "\n%s: %s" "$secret_key" "$secret_value" >> "${temp_file}"

    ansible-vault encrypt "${temp_file}" --vault-password-file <(printf "%s" "$VAULT_PASS") --output "${SECRETS_FILE}" 2>/dev/null

    rm "${temp_file}"

    msg_succ "Secret '${secret_key}' has been added to the Vault successfully."
  else
    msg_succ "Secret '${secret_key}' already exists in the Vault."
  fi
}

run_k8s_secret_creation() {
  msg_alert "This script will create the GitLab registry secret in Kubernetes."
  read -p "Enter the email for the registry secret: " REGISTRY_EMAIL
  read -p "Enter a comma-separated list of namespaces (e.g., hotela,p2p-chat): " NAMESPACE_LIST
  check_and_set_secret "gitlab_deploy_token" "Please enter your GitLab Deploy Token"
  msg_info "Running the Ansible playbook..."
  ansible-playbook "${PLAYBOOKS_DIR}/k8s-gitlab-registry-secret.yml" \
    -e "target_namespaces_str=${NAMESPACE_LIST}" \
    -e "registry_email=${REGISTRY_EMAIL}" \
    --vault-password-file <(printf "%s" "$VAULT_PASS")
  msg_succ "Operation completed successfully!"
}

show_install_menu() {
  PS3="Choose an installation option: "

  options=("Install a Specific Service" "Exit")

  select opt in "${options[@]}"; do
    case $opt in
      "Install a Specific Service")
        msg_alert "Select the service you want to install:"

        service_names=()
        for entry in "${SERVICE_PLAYBOOKS[@]}"; do
          service_names+=("$(echo "$entry" | cut -d':' -f1)")
        done

        select target_service in "${service_names[@]}"; do
          if [[ -n "$target_service" ]]; then
            for entry in "${SERVICE_PLAYBOOKS[@]}"; do
              name=$(echo "$entry" | cut -d':' -f1)
              params=$(echo "$entry" | cut -d':' -f2)
              secret_key=$(echo "$entry" | cut -d':' -f3)

              if [[ "$name" == "$target_service" ]]; then
                CMD="ansible-playbook ${PLAYBOOKS_DIR}/${name}.yml"

                if [[ "$params" == "--ask-vault-pass" ]]; then
                  if [[ -n "$secret_key" ]]; then
                    check_and_set_secret "$secret_key" "Please, enter the value for '${secret_key}'"
                  elif [[ -z "$VAULT_PASS" ]]; then
                     read -sp "Enter Ansible Vault password: " VAULT_PASS
                     echo
                  fi
                  CMD+=" --vault-password-file <(printf \"%s\" \"$VAULT_PASS\")"
                fi

                msg_info "Starting installation of '${name}'..."
                eval "$CMD"
                msg_succ "Installation of '${name}' completed."
                break
              fi
            done
          else
            msg_error "Invalid selection."
          fi
          break
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
}

msg_title "Ansible Homelab Orchestrator"
PS3="Choose an operation area (enter the number): "
main_options=("Install Services" "Manage Kubernetes Secrets" "Exit")

select opt in "${main_options[@]}"; do
  case $opt in
    "Install Services")
      show_install_menu
      break
      ;;
    "Manage Kubernetes Secrets")
      run_k8s_secret_creation
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
