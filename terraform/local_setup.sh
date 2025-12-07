#!/bin/bash

# =================================================================================
# SCRIPT DE CONFIGURAÇÃO INICIAL DO TERRAFORM
# =================================================================================

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}=== Starting Terraform initial setup ===${NC}"

echo -e "\n${YELLOW}--> Checking Terraform installation...${NC}"
if ! command -v terraform &> /dev/null; then
    echo "Terraform not found. Installing it..."

    sudo apt-get update
    sudo apt-get install -y gnupg software-properties-common

    wget -O- https://apt.releases.hashicorp.com/gpg | \
    gpg --dearmor | \
    sudo tee /usr/share/keyrings/hashicorp-archive-keyring.gpg > /dev/null

    gpg --no-default-keyring \
    --keyring /usr/share/keyrings/hashicorp-archive-keyring.gpg \
    --fingerprint

    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(grep -oP '(?<=UBUNTU_CODENAME=).*' /etc/os-release || lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list

    sudo apt update

    sudo apt-get install terraform

    echo -e "${GREEN}Terraform installed successfully.${NC}"
else
    echo -e "${GREEN}Terraform is already installed.${NC}"
    exit
fi

terraform --version

echo -e "\n${YELLOW}--> Setting up Terraform autocomplete...${NC}"
terraform -install-autocomplete

if [ $? -ne 0 ]; then
    echo -e "${YELLOW}Failed to set up Terraform autocomplete. Continuing...${NC}"
else
    echo -e "${GREEN}Terraform autocomplete set up successfully.${NC}"
fi

echo -e "${GREEN}Terraform setup completed successfully!${NC}"
