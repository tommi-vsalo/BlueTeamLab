# OpenTofu – Prototype Configuration Files (Summary & Documentation)

## What “OpenTofu configuration files” means

In this project, OpenTofu configuration files refer to the .tf files that define how the virtual machines are created.

These files tell OpenTofu:
- Which VMs to create.
- Which OVA images to import.
- What hardware resources each VM should have.
- How networking is set up.
- How VMs are destroyed.
- How the entire environment is deployed with tofu apply.

For this prototype, the primary configuration file is:
**main.tf** — the core automation file

This file includes:
- OVA import logic.
- CPU / RAM / VRAM settings.
- Network adapter configuration.
- VM naming.
- VM deletion logic.
- PowerShell execution via local-exec.



## VMs created by OpenTofu

OpenTofu provisions the following machines automatically:
- Ansible Controller (Ubuntu 24.04)
- Logging Server (Ubuntu 24.04)
- Windows Server (dc01)
- Windows Client (cl01)

All machines are created from prebuilt OVA images.




## What OpenTofu does technically

**1. Import OVA images**
For each VM:
- Check if a VM with the same name exists
- If not: import the correct OVA image
- Assign the VM name


**2. Applies hardware configuration**
After import, OpenTofu sets:
- CPU count
- Memory size
- Video memory
- Network adapters (NAT + Internal Network)

**3. Defines network layout**
All VMs have:
- NIC1 = NAT (Internet access)
- NIC2 = “lab-int” (internal lab network)

**4. Handles VM deletion**
`tofu destroy` runs:
`VBoxManage unregistervm --delete`

This removes the VM cleanly from VirtualBox.



## Base Images (OVA files)
The project uses two OVA base images:

### Ubuntu OVA — testikone.ova
Used for:
- Ansible Controller
- Logging Server

Contains:
- Guest Additions
- SSH enabled
- Python3
- `apt update & upgrade`
- Finnish keyboard
- Basic bootstrap steps


### Windows OVA — konetesti.ova
Used for:
- Windows Server (dc01)
- Windows Client (cl01)

Contains:
- Guest Additions
- WinRM enabled
- Port 5985 allowed
- Basic bootstrap steps

**OVA files** are stored in OneDrive:
OpenTofu / OVA-images/

Before running OpenTofu, place them locally:
images/testikone.ova
images/konetesti.ova




## How to deploy the environment

### 1. Place OVA images into the images/ directory


### 2. Run:
`tofu init`
`tofu apply`

OpenTofu will:
- Import OVA images
- Configure CPU/RAM/VRAM
- Create NAT + lab-int networking
- Register VMs in VirtualBox
- Produce a fully reproducible prototype environment




## 7. What OpenTofu does NOT configure
These will be handled later via Ansible:
- Static IP addresses
- Domain join
- Windows AD/DNS services
- Graylog / Wazuh installations
- Logging agents
- Security hardening
- OS-level settings

OpenTofu’s role is infrastructure provisioning, not OS configuration.
