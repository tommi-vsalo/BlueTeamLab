#!/usr/bin/env bash
set -e

sudo apt update
sudo apt install -y ansible python3-pip

sudo apt install -y python3-winrm

ansible-galaxy collection install ansible.windows community.windows

mkdir -p ansible-controller/{playbooks,inventory}
