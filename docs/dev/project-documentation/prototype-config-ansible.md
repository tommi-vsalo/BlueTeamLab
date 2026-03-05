# Prototype Configurations (OpenTofu)

This document lists the necessary configurations that have to be implemented for the prototype build in order to deploy a ready lab environment.


## Ansible

Ansible is used to configure the virtual machines after provisioning to provide a ready lab environment. The configurations have to be applied in the following order to ensure the environment functions:


### Table of Configurations


| Virtual Machine     | Network                         | IP-Address       |
|---------------------|----------------------------------|------------------|
| Ansible Controller  | NAT (DHCP), Internal: lab-int    | 10.10.10.10/24   |
| Windows Server      | NAT (DHCP), Internal: lab-int    | 10.10.10.20/24   |
| Windows Client      | NAT (DHCP), Internal: lab-int    | 10.10.10.30/24   |
| Logging Server      | NAT (DHCP), Internal: lab-int    | 10.10.10.40/24   |


### Step 1 - Domain Controller Setup

**Windows Server**:
- Install Active Directory services
- Promote server to Domain Controller
- Create new forest `blueteamlab.local`
- Configure DNS `10.10.10.20`
- Reboot after promotion

### Step 2 - Domain Client Configuration

**Windows Client**: 
- Configure DNS `10.10.10.20`
- Join domain `blueteamlab.local`
- Reboot after domain join

### Step 3 - AD Configuration

**Windows Server**: 
- Create Organizational Units
- Create new user account
- Create service account with SPN
- Enable advanced audit policies:
  -  Logon events
  -  Kerberos Service Ticket Operations
  -  Directory Service Access

### Step 4 - Logging Setup

**Logging Server**:
- Install Graylog and required dependencies (utilize maintained public role OR dockerized)
- Configure log input from `dc01`

**Windows Server**: 
- Install Winlogbeat
- Configure output to `log01`
- Restart logging service

### Step 5 - Scripted Attack Setup

**Windows Client**:
- Load scripted attack

Ansible configuration should be tested incrementally to ensure each step functions as it is supposed to.
