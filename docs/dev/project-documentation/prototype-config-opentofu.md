# Prototype Configurations (OpenTofu)

This document lists the virtual machine and machine image specifications that have to be implemented for the prototype build.

## Virtual Machines

The prototype build consists of four virtual machines.

- **Ansible Controller**: Configures the other three VMs.

- **Windows Server**: Domain controller, sends logging files to the logging server.

- **Windows Client**: Client machine within the domain, origin of scripted attacks.

- **Logging Server**: Collects and displays logs from the windows server.


## OpenTofu

OpenTofu is used to deploy basic virtual machines using `VBoxManage` and the OVA import tool. 
It handles:

- VM creation (import from OVA)
- CPU/RAM/VRAM settings
- Network adapter configuration  
- Automatic delete on `tofu destroy`  
- Name assignment


### Base Images

- Ubuntu base OVAs: **testikone-ansible.ova** & **testikone-logging.ova**
- Windows base OVAs: **konetesti-server.ova** & **konetesti-client.ova**


The original plan was to reuse only two OVA images:
- One Ubuntu OVA for both Ansible + Logging
- One Windows OVA for both Server + Client

This approach turned out to be flawed, and it caused multiple issues throughout the build process.



### Network Design

**Adapter 1 (NAT)**

- Provides internet access for updates and package installation.

- DHCP assigned by VirtualBox.

**Adapter 2 (Internal: lab-int)**

- Used for all internal traffic.

- Subnet: `10.10.10.0/24`.

- Static IP assigned upon provisioning (see table below).

- Internal adapter has no gateway configured.


**DNS Configuration**

- `dc01` acts as internal DNS server.

- `cl01` and `log01` use `10.10.10.20` as DNS


### Table of Specifications

| Virtual Machine | Hostname | OVA image | CPU | RAM (MB) | VRAM | Disk size | NIC1 | NIC2 |
|----------|----------|----------|----------|----------|----------|----------|----------|----------|
| Ansible Controller | ansible-con | testikone.ova | 2 | 4096 | 16 | 25,00 GB | NAT | lab-int |
| Windows Server | dc01 | konetesti.ova | 2 | 4096 | 128 | 50,00 GB | NAT | lab-int |
| Windows Client | cl01 | konetesti.ova | 2 | 4096 | 128 | 50,00 GB | NAT | lab-int |
| Logging Server | log01 | testikone.ova | 2 | 4096 | 16 | 25,00 GB | NAT | lab-int |


### What OpenTofu **can** configure?

OpenTofu (with PowerShell + VBoxManage) can configure the following:
- VM name.  
- CPU count.  
- RAM size.  
- VRAM size.  
- NIC1 (NAT) and NIC2 (Internal) order.  
- OVA import.  
- VM deletion (`unregistervm --delete`).

### And what OpenTofu **cannot** configure?

It cannot configure the following things:
- Windows domain services.  
- AD setup.  
- Wazuh / Graylog. 
- WinRM (already done in base image).
