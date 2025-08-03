#!/bin/bash

# =================================================================================
# SCRIPT DE CONFIGURAÇÃO INICIAL DO ANSIBLE NA MÁQUINA LOCAL
# =================================================================================

source "$BASH_BEAUTIFUL"

SSH_KEY_PATH="$HOME/.ssh/id_ed25519"
REMOTE_HOST="192.168.1.99"
ANSIBLE_CONTROLLER_IP="192.168.1.254"
REMOTE_USER="root"
GROUP_VARS_DIR="group_vars"
SECRETS_FILE="${GROUP_VARS_DIR}/secrets.yml"
BACKUP_USER="restic-backup"
BACKUP_REPO_DIR="/home/${BACKUP_USER}/repo"
TOTAL_STEPS=7

set -e

msg_title "Starting Ansible initial setup"

msg_step "1" "${TOTAL_STEPS}" "Checking Ansible & Dependencies..."

if ! command -v ansible &> /dev/null; then
    msg_info "Ansible not found. Installing it..."
    sudo apt-get update
    sudo apt-get install software-properties-common -y
    sudo add-apt-repository --yes --update ppa:ansible/ansible
    sudo apt-get install ansible -y
    msg_succ "Ansible installed successfully."
else
    msg_succ "Ansible is already installed."
fi

if ! command -v htpasswd &> /dev/null; then
    msg_info "htpasswd not found. Installing apache2-utils..."
    sudo apt-get install -y apache2-utils
fi
msg_succ "All required packages are installed."
ansible --version

msg_step "2" "${TOTAL_STEPS}" "Checking for ed25519 SSH key..."

if [ ! -f "${SSH_KEY_PATH}.pub" ]; then
    msg_info "ed25519 SSH key not found. Generating a new key..."
    ssh-keygen -t ed25519 -N "" -f "${SSH_KEY_PATH}"
    msg_succ "ed25519 SSH key generated successfully at ${SSH_KEY_PATH}.pub"
else
    msg_succ "ed25519 SSH key found at ${SSH_KEY_PATH}.pub"
fi

msg_step "3" "${TOTAL_STEPS}" "Setting up local backup environment..."
if id "${BACKUP_USER}" &>/dev/null; then
    msg_succ "Backup user '${BACKUP_USER}' already exists."
else
    msg_info "Creating backup user '${BACKUP_USER}'..."
    sudo useradd -m -s /bin/bash "${BACKUP_USER}"
    msg_succ "User '${BACKUP_USER}' created successfully."
fi

msg_info "Setting up backup directories and permissions..."
sudo mkdir -p "${BACKUP_REPO_DIR}"
sudo chown -R "${BACKUP_USER}:${BACKUP_USER}" "/home/${BACKUP_USER}"

msg_info "Configuring SSH access for backup user..."
sudo -u "${BACKUP_USER}" mkdir -p "/home/${BACKUP_USER}/.ssh"
sudo cp "${SSH_KEY_PATH}.pub" "/home/${BACKUP_USER}/.ssh/authorized_keys"
sudo chown -R "${BACKUP_USER}:${BACKUP_USER}" "/home/${BACKUP_USER}/.ssh"
sudo chmod 700 "/home/${BACKUP_USER}/.ssh"
sudo chmod 600 "/home/${BACKUP_USER}/.ssh/authorized_keys"

msg_info "Creating backup user group and adding user to it..."
if ! getent group backup-admins &>/dev/null; then
    sudo groupadd backup-admins
    msg_succ "Backup group created successfully."
else
    msg_succ "Backup group already exists."
fi

sudo usermod -aG backup-admins "${BACKUP_USER}"
sudo usermod -aG backup-admins "$(whoami)"

msg_info "Applying group permissions to the backup repository..."
sudo chown -R "${BACKUP_USER}:${BACKUP_GROUP}" "${BACKUP_REPO_DIR}"

sudo chmod -R g+rX "${BACKUP_REPO_DIR}"
msg_succ "Group permissions applied successfully."

msg_succ "Local backup environment is ready."

msg_step "4" "${TOTAL_STEPS}" "Creating secrets file with Ansible Vault..."

mkdir -p ${GROUP_VARS_DIR}

while true; do
    read -sp "Enter a new password for Ansible Vault (this will encrypt your secrets): " VAULT_PASS
    echo
    read -sp "Confirm the Vault password: " VAULT_PASS_CONFIRM
    echo
    if [ "$VAULT_PASS" = "$VAULT_PASS_CONFIRM" ]; then
        break
    else
        msg_error "Passwords do not match. Please try again."
    fi
done

msg_info "Now, let's define the default credentials for your services."

read -p "Enter the default admin username for services: " ADMIN_USER

while true; do
    read -sp "Enter the default admin password for services: " ADMIN_PASS
    echo
    read -sp "Confirm the admin password: " ADMIN_PASS_CONFIRM
    echo
    if [ "$ADMIN_PASS" = "$ADMIN_PASS_CONFIRM" ]; then
        break
    else
        msg_error "Passwords do not match. Please try again."
    fi
done

msg_step "5" "${TOTAL_STEPS}" "Configuring Restic password..."

while true; do
    read -p "Use the same password for Restic backups? (y/n): " use_same_pass
    case "$use_same_pass" in
        [Yy]* )
            RESTIC_PASS="$ADMIN_PASS"
            msg_succ "Restic password set to the admin password."
            break
            ;;
        [Nn]* )
            while true; do
                read -sp "Enter a new password for Restic backups: " RESTIC_PASS_NEW
                echo
                read -sp "Confirm the Restic password: " RESTIC_PASS_CONFIRM
                echo
                if [ "$RESTIC_PASS_NEW" = "$RESTIC_PASS_CONFIRM" ]; then
                    RESTIC_PASS="$RESTIC_PASS_NEW"
                    msg_succ "New Restic password has been set."
                    break
                else
                    msg_error "Passwords do not match. Please try again."
                fi
            done
            break
            ;;
        * )
            msg_error "Please answer yes (y) or no (n)."
            ;;
    esac
done

msg_step "6" "${TOTAL_STEPS}" "Getting information for GitLab..."
msg_info "Email gitlab user will be used to send notifications and alerts"

while true; do
  read -p "Enter email for GitLab: " GITLAB_EMAIL

  msg_info "The email you entered is: $GITLAB_EMAIL"
  read -p "Is this correct? (y/n): " confirm_email

  if [[ "$confirm_email" =~ ^[Yy]$ ]]; then
    if [[ "$GITLAB_EMAIL" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
      break
    else
      msg_error "Invalid email format. Please try again."
    fi
    break
  else
    msg_error "Please re-enter the email."
  fi
done

msg_info "Now, is necessary generate a token for GitLab use the email ${GITLAB_EMAIL} to send notifications and alerts."
msg_info "If you using gmail, read the instructions at https://support.google.com/mail/answer/185833?hl=en"
msg_info "After generating the token, copy it and paste it below."

while true; do
    read -sp "Enter the GitLab token: " GITLAB_TOKEN
    echo
    read -sp "Confirm the GitLab token: " GITLAB_TOKEN_CONFIRM
    echo
    if [ "$GITLAB_TOKEN" = "$GITLAB_TOKEN_CONFIRM" ]; then
        msg_succ "GitLab token confirmed."
        break
    else
        msg_error "Tokens do not match. Please try again."
    fi
done

msg_succ "Gitlab information collected successfully"

msg_step "6" "${TOTAL_STEPS}" "Generating and encrypting variables..."

msg_info "Generating bcrypt hash for the admin password..."
HASHED_PASS=$(htpasswd -nbB -C 10 "$ADMIN_USER" "$ADMIN_PASS" | cut -d':' -f2)
msg_succ "Hash generated successfully."

YAML_CONTENT=$(cat <<EOF
default_admin_user: "$ADMIN_USER"
admin_pass: "$ADMIN_PASS"
hashed_admin_pass: "$HASHED_PASS"
restic_password: "$RESTIC_PASS"
ansible_controller_ip: "$ANSIBLE_CONTROLLER_IP"
homelab_email_user: "$GITLAB_EMAIL"
homelab_email_token: "$GITLAB_TOKEN"
EOF
)

printf "%s" "$YAML_CONTENT" | ansible-vault encrypt --vault-password-file <(printf "%s" "$VAULT_PASS") > ${SECRETS_FILE}
msg_succ "Encrypted secrets file created successfully at '${SECRETS_FILE}'."
msg_alert "IMPORTANT: Remember your Vault password. You will need it to run playbooks."

msg_step "7" "${TOTAL_STEPS}" "Final instructions"

echo ""
msg_title "MANUAL ACTION REQUIRED"
echo ""
msg_info "Local setup is complete. Now, authorize this machine on your server."
msg_alert "Copy and run the command below in your terminal. It will prompt for the server password."
echo ""
msg_info "      ssh-copy-id -i ${SSH_KEY_PATH}.pub ${REMOTE_USER}@${REMOTE_HOST}"
echo ""
msg_info "After the command is successful, you will be able to use Ansible without a password."
echo ""
msg_succ "Setup completed successfully!"
