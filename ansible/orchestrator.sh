#!/usr/bin/env bash

# =================================================================================
# ORQUESTRADOR DE INSTALAÇÃO DE SERVIÇOS COM ANSIBLE
# =================================================================================

set -e

source "$BASH_BEAUTIFUL"

PLAYBOOKS_DIR="playbooks"
SECRETS_FILE="group_vars/secrets.yml"
export ANSIBLE_COLLECTIONS_PATH="./collections"
LINE="=========================================================================="

# Display name : Playbook name : Parameters : Secret keys
SERVICES_INSTALL_UPDATE_PLAYBOOKS=(
  "Adguard Home:adguard:--ask-vault-pass:"
  "Nginx Proxy Manager:npm::"
  "Uptime Kuma:kuma::"
  "Heimdall:heimdall::"
  "Hashicorp Vault:vault::"
  "PostgreSQL:postgres:--ask-vault-pass:"
  "Kubernetes:kubernetes::"
  "Gitlab CE:gitlab:--ask-vault-pass:"
  "Gitlab Runner:gitlab-runner:--ask-vault-pass:gitlab_runner_token"
  "SonarQube:sonarqube:--ask-vault-pass:sonarqube_db_user,sonarqube_db_password"
  "My Speed:myspeed::"
  "Beszel:beszel::"
  "Beszel Agent:beszel-agent:--ask-vault-pass,--limit:beszel_agent_token,beszel_public_key,beszel_hub_url"
)

SERVICES_UNINSTALL_PLAYBOOKS=(
  "Beszel Agent:uninstall-beszel-agent:--limit:"
)

PROXMOX_PLAYBOOKS=(
  "Setup Proxmox Host:proxmox:--ask-vault-pass:proxmox_admin_email"
  "Create VM Template Cloud Init:create_vm_template::"
)

get_all_hosts() {
  awk '/^\[(lxc_containers|vms)\]/{f=1;next} /^\[/{f=0} f && !/^\s*($|#)/{print $1}' inventory.ini
}

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

k8s_gitlab_integration() {
  msg_alert "This script will create the GitLab registry secret in Kubernetes."
  read -p "Enter the email for the registry secret: " REGISTRY_EMAIL
  read -p "Enter a comma-separated list of namespaces (e.g., hotela,p2p-chat): " NAMESPACE_LIST
  check_and_set_secret "gitlab_deploy_token" "Please enter your GitLab Deploy Token"
  msg_info "Running the Ansible playbook..."
  ansible-playbook "${PLAYBOOKS_DIR}/gitlab-k8s-integration.yml" \
    -e "target_namespaces_str=${NAMESPACE_LIST}" \
    -e "registry_email=${REGISTRY_EMAIL}" \
    --vault-password-file <(printf "%s" "$VAULT_PASS")
  msg_succ "Operation completed successfully!"
}

k8s_vault_integration() {
  msg_alert "This will configure the integration between Vault, PostgreSQL, and Kubernetes."
  msg_info "The script will use the 'apps' list defined inside the playbook."
  read -p "Do you want to proceed? (y/n): " confirm
  if [[ "$confirm" =~ ^[Yy]$ ]]; then
    check_and_set_secret "vault_root_token" "Please enter your Vault Root Token"
    msg_info "Running the Vault-Postgres integration playbook..."
    ansible-playbook "${PLAYBOOKS_DIR}/vault-postgres-k8s-integration.yml" \
      --ask-become-pass \
      --vault-password-file <(printf "%s" "$VAULT_PASS")
    msg_succ "Integration playbook completed successfully."
  else
    msg_error "Operation cancelled."
  fi
}

k8s_app_secret_creation() {
  msg_alert "This will create/update a KV secret for a specific application in Vault."
  msg_info "Secrets are defined in the file './app_secrets/<app_name>.yml'. Ensure this file exists before proceeding."

  read -p "Enter the application name (e.g., hotela): " APP_NAME

  local SECRETS_FILE_PATH="app_secrets/${APP_NAME}.yml"

  if [ ! -f "$SECRETS_FILE_PATH" ]; then
    msg_error "Error: File not found at '${SECRETS_FILE_PATH}'."
    exit 1
  fi

  check_and_set_secret "vault_root_token" "Please enter your Vault Root Token"

  msg_info "Running playbook to write secrets for '${APP_NAME}'..."

  ansible-playbook "${PLAYBOOKS_DIR}/vault-create-secrets.yml" \
    -e "app_name=${APP_NAME}" \
    -e "secrets_file_path=${SECRETS_FILE_PATH}" \
    --vault-password-file <(printf "%s" "$VAULT_PASS")

  msg_succ "Secrets for '${APP_NAME}' have been successfully written to Vault."
}

run_playbook() {
  local name="$1"
  local params="$2"
  local secret_keys_str="$3"

  local limit_flag=""
  local selected_hosts_display="all hosts"
  local CMD="ansible-playbook ${PLAYBOOKS_DIR}/${name}.yml"

  if [[ "$params" == *"--limit"* ]]; then
    msg_alert "This operation requires a host target. Please select:"
    hosts=($(get_all_hosts))

    echo "Available hosts:"
    for i in "${!hosts[@]}"; do
      echo "  $((i+1))) ${hosts[$i]}"
    done
    echo ""
    read -p "Enter number(s) separated by comma (e.g., 1,3), or 'all': " user_selection

    if [[ -z "$user_selection" ]]; then
      msg_error "No selection made. Aborting."
      return 1
    fi

    if [[ "$user_selection" != "all" ]]; then
      local selected_host_names=""
      IFS=',' read -r -a selections <<< "$user_selection"

      for index in "${selections[@]}"; do
        if ! [[ "$index" =~ ^[0-9]+$ ]] || [ "$index" -lt 1 ] || [ "$index" -gt "${#hosts[@]}" ]; then
          msg_error "Invalid selection: '${index}'. Aborting."
          return 1
        fi

        host_index=$((index-1))

        if [ -z "$selected_host_names" ]; then
          selected_host_names="${hosts[$host_index]}"
        else
          selected_host_names+=",${hosts[$host_index]}"
        fi
      done

      limit_flag="--limit ${selected_host_names}"
      selected_hosts_display="${selected_host_names}"
    fi
  fi

  if [[ "$params" == *"--ask-vault-pass"* ]]; then
    if [[ -n "$secret_keys_str" ]]; then
      IFS=',' read -r -a secret_keys_arr <<< "$secret_keys_str"

      for secret_key in "${secret_keys_arr[@]}"; do
        check_and_set_secret "$secret_key" "Please, enter the value for '${secret_key}'"
      done

    elif [[ -z "$VAULT_PASS" ]]; then
      read -sp "Enter Ansible Vault password: " VAULT_PASS
      echo
    fi
    CMD+=" --vault-password-file <(printf \"%s\" \"$VAULT_PASS\")"
  fi

  CMD+=" ${limit_flag}"

  msg_info "\nStarting execution of '${name}' on target(s): ${selected_hosts_display}..."
  eval "$CMD"
  msg_succ "Execution of '${name}' completed."
}

show_k8s_menu() {
  PS3="Choose an option: "
  options=("Setup Gitlab Registry + k8s" "Setup Vault + k8s + PostgreSQL" "Exit")

  select opt in "${options[@]}"; do
    case $opt in
      "Setup Gitlab Registry + k8s")
        k8s_gitlab_integration
        break
        ;;
      "Setup Vault + k8s + PostgreSQL")
        k8s_vault_integration
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

show_menu() {
  local menu_title="$1"
  local -n playbook_array=$2

  local display_names=()
  for entry in "${playbook_array[@]}"; do
    display_names+=("$(echo "$entry" | cut -d':' -f1)")
  done

  display_names+=("Back to Main Menu")

  PS3="Choose an option: "

  select opt in "${display_names[@]}"; do
    if [[ "$opt" == "Back to Main Menu" ]]; then
      break
    elif [[ -n "$opt" ]]; then
      for entry in "${playbook_array[@]}"; do
        display_name=$(echo "$entry" | cut -d':' -f1)

        if [[ "$display_name" == "$opt" ]]; then
          playbook_name=$(echo "$entry" | cut -d':' -f2)
          params=$(echo "$entry" | cut -d':' -f3)
          secret_keys_str=$(echo "$entry" | cut -d':' -f4)

          run_playbook "$playbook_name" "$params" "$secret_keys_str"
          break 2
        fi
      done
    else
      msg_error "Invalid selection."
    fi
  done
}

show_vault_menu() {
  PS3="Choose an option: "
  options=("Create/Update App Secret" "Exit")

  select opt in "${options[@]}"; do
    case $opt in
      "Create/Update App Secret")
        k8s_app_secret_creation
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

show_proxmox_menu() {
  PS3="Choose a Proxmox operation: "

  proxmox_names=()
  for entry in "${PROXMOX_PLAYBOOKS[@]}"; do
    proxmox_names+=("$(echo "$entry" | cut -d':' -f1)")
  done

  select target_proxmox in "${proxmox_names[@]}"; do
    if [[ -n "$target_proxmox" ]]; then
      for entry in "${PROXMOX_PLAYBOOKS[@]}"; do
        display_name=$(echo "$entry" | cut -d':' -f1)
        playbook_name=$(echo "$entry" | cut -d':' -f2)
        params=$(echo "$entry" | cut -d':' -f3)
        secret_keys_str=$(echo "$entry" | cut -d':' -f4)

        if [[ "$display_name" == "$target_proxmox" ]]; then
          run_playbook "$playbook_name" "$params" "$secret_keys_str"
          break
        fi
      done
    else
      msg_error "Invalid selection."
    fi
    break
  done
}

show_secrets_menu() {
  PS3="Choose a secrets operation: "
  options=("View Secrets" "Edit Secrets" "Back to Main Menu")

  if [[ ! -f "${SECRETS_FILE}" ]]; then
    msg_error "Secrets file '${SECRETS_FILE}' does not exist. Please, create it first"
    return
  fi

  if [[ -z "$VAULT_PASS" ]]; then
    read -sp "Enter Ansible Vault password to access secrets: " VAULT_PASS
    echo
  fi


while true; do
  select opt in "${options[@]}"; do
    case $opt in
      "View Secrets")
        msg_info "${LINE}"
        ansible-vault view "${SECRETS_FILE}" --vault-password-file <(printf "%s" "$VAULT_PASS")
        msg_info "${LINE}"
        break
        ;;
      "Edit Secrets")
        ansible-vault edit "${SECRETS_FILE}" --vault-password-file <(printf "%s" "$VAULT_PASS")
        break
        ;;
      "Back to Main Menu")
        break 2
        ;;
      *)
        msg_error "Invalid option: $REPLY"
        ;;
    esac
  done
done
}

# =================================================================================
# PONTO DE ENTRADA DO SCRIPT
# =================================================================================
msg_title "Ansible Homelab Orchestrator"
PS3="Choose an operation area: "
main_options=("Install/Update Services" "Uninstall Services" "Manage Kubernetes" "Manage Vault" "Manage Ansible Secrets" "Exit")

while true; do
  select opt in "${main_options[@]}"; do
    case $opt in
      "Install/Update Services")
        show_menu "Select the service to install/update:" SERVICES_INSTALL_UPDATE_PLAYBOOKS
        break
        ;;
      "Uninstall Services")
        show_menu "Select the service to uninstall:" SERVICES_UNINSTALL_PLAYBOOKS
        break
        ;;
      "Manage Kubernetes")
        show_k8s_menu
        break
        ;;
      "Manage Vault")
        show_vault_menu
        break
        ;;
      "Manage Ansible Secrets")
        show_secrets_menu
        break
        ;;
      "Exit")
        exit 0
        ;;
      *)
        msg_error "Invalid option: $REPLY"
        ;;
    esac
  done
done