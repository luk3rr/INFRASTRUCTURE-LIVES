#!/bin/bash

set -e

ansible-playbook playbooks/setup_proxmox_host.yml
ansible-playbook playbooks/create_vm_template.yml
