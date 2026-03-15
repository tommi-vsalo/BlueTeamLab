# Prototype ansible configurations and first domain controller promotions and installations
---
## What i have.
Ansible-conroller 10.10.10.10
Windows Client 10.10.10.30

Ping is successfull to eachother.

## Ansible-setup
on ansible-conroller i run the this script:
```bash 
#!/usr/bin/env bash
set -e

sudo apt update
sudo apt install -y ansible python3-pip
python3 -m pip install --user pywinrm
ansible-galaxy collection install ansible.windows community.windows

mkdir -p ansible-controller/{playbooks,inventory}
```

This installs ansible and creates the necessary directories for the machine to become a controller

To make sure everything is installed correctly i run ansible --version

![ansible_verison]()
