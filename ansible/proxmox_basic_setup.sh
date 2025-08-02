#!/bin/bash

set -e

ansible-playbook proxmox_basic_setup/setup_proxmox_host.yml
ansible-playbook proxmox_basic_setup/create_vm_template.yml
