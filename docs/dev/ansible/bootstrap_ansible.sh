#!/usr/bin/env bash
set -e

sudo apt update
sudo apt install -y ansible python3-pip
python3 -m pip install --user pywinrm
ansible-galaxy collection install ansible.windows community.windows

mkdir -p ansible-controller/{playbooks,inventory}
