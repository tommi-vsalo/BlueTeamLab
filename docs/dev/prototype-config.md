# Prototype Configurations

This document lists the necessary configurations that have to be implemented for the prototype build. 

## 1. Virtual Machines

The prototype build consists of four virtual machines. This document defines their configurations, networks and OpenTofu provisioning details.

- **Ansible Controller**: Configures the other three VMs.

- **Windows Server**: Domain controller, sends logging files to the logging server.

- **Windows Client**: Client machine within the domain, origin of scripted attacks.

- **Logging Server**: Collects and displays logs from the windows server.

## 2. OpenTofu

OpenTofu is used to deploy basic virtual machines using `VBoxManage` and the OVA import tool. 
It handles:

- VM creation (import from OVA)
- CPU/RAM/VRAM settings
- Network adapter configuration  
- Automatic delete on `tofu destroy`  
- Name assignment

### Base Images

- Ubuntu base OVA: **testikone.ova**  
- Windows base OVA: **konetesti.ova** 


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

- `cl01` and `log01` use `10.10.10.20/24` as DNS

### Table of Specifications

Name, image, CPU, RAM, Disk size, NIC order.

| Virtual Machine | Hostname | OVA image | CPU | RAM (MB) | VRAM | Disk size | NIC1 | NIC2 |
|----------|----------|----------|----------|
| Ansible Controller | ansible-con | testikone.ova | 2 | 4096 | 16 | 25,00 GB | NAT | lab-int |
| Windows Server | dc01 | konetesti.ova | 2 | 4096 | 128 | 50,00 GB | NAT | lab-int |
| Windows Client | cl01 | konetesti.ova | 2 | 4096 | 128 | 50,00 GB | NAT | lab-int |
| Logging Server | log01 | testikone.ova | 2 | 4096 | 16 | 25,00 GB | NAT | lab-int |

### Table of Configrations


| Virtual Machine     | Hostname    | Network                         | IP-Address       |
|---------------------|-------------|----------------------------------|------------------|
| Ansible Controller  | ansible-con | NAT (DHCP), Internal: lab-int    | 10.10.10.10/24   |
| Windows Server      | dc01        | NAT (DHCP), Internal: lab-int    | 10.10.10.20/24   |
| Windows Client      | cl01        | NAT (DHCP), Internal: lab-int    | 10.10.10.30/24   |
| Logging Server      | log01       | NAT (DHCP), Internal: lab-int    | 10.10.10.40/24   |


Necessary Ansible preparations (SSH keys, WinRM, etc.) also have to be inserted at this stage or Ansible will not work.


## 3. Ansible
