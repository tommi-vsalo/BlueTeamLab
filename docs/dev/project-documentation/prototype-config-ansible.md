# Prototype Configurations (Ansible)

This document lists the necessary Ansible configurations that have to be implemented for the prototype build. Ansible is used to configure the virtual machines within the lab environment.


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
- Create new user account
- Create service account
- Configure SPN to service account

- Enable advanced audit policies:
  -  Logon events
  -  Kerberos Service Ticket Operations
  -  Directory Service Access
  
- In addition, detection testing would benefit from:
  - Account Logon
  - Account Management
  - Process Creation with command-line logging
  - Object Access
  - Policy Change
 
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

### Step 4 - Logging Setup

**Logging Server**:
- Install Graylog and required dependencies (utilize maintained public role OR dockerized)
- Configure log input from `dc01`

**Windows Server**: 
- Install Winlogbeat
- Forward relevant events to `log01` 
- Restart and enable Winlogbeat service

### Step 5 - Scripted Attack Setup

**Windows Client**:
- Load scripted attack
