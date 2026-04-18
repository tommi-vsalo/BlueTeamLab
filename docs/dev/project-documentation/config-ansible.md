# Ansible Configurations

This document lists the necessary configurations that have to be implemented using Ansible. Ansible is used to configure the virtual machines within the lab environment.


### Table of Configurations


| Virtual Machine     | Network                         | IP-Address       |
|---------------------|----------------------------------|------------------|
| Ansible Controller  | NAT (DHCP), Internal: lab-int    | 10.10.10.10/24   |
| Windows Server      | NAT (DHCP), Internal: lab-int    | 10.10.10.20/24   |
| Windows Client      | NAT (DHCP), Internal: lab-int    | 10.10.10.30/24   |
| Logging Server      | NAT (DHCP), Internal: lab-int    | 10.10.10.40/24   |

### Ansible Principles

Configuration should be applied and tested in phases. Each phase must complete successfully and validated before the next phase is run. Reboots must be handled cleanly in Ansible.


### Step 1 - Domain Controller Setup

Configure the Windows Server as the Domain Controller and prepare the domain

**Windows Server**:
- Install Active Directory services and DNS role
- Promote server to Domain Controller
- Create new forest `blueteamlab.local`
- Configure DNS `10.10.10.20`
- Reboot after promotion

Verify that AD services are running and that the created domain exists.

### Step 2 - Domain Client Configuration

**Windows Client**: 
- Configure DNS to `10.10.10.20`
- Join domain `blueteamlab.local`
- Reboot after domain join

Verify that the Client is a part of the domain

### Step 3 - AD Configuration

**Windows Server**: 
- Create Organizational Units
- Create new admin account
- Disable built-in admin account
- Create new user accounts
- Add user accounts to groups
 
### OU-Outline

- BlueteamLab
  - Servers
    - Domain Controllers
  - Workstations
  - Users
    - Admins
    - Standard Users
  - Service Accounts
  - Groups
**Windows Client**:
- Load scripted attack
