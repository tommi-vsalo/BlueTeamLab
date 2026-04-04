# User Guide for BlueTeamLab

## What is the purpose of this lab?

This lab a training environment where students can explore and test:
- Windows Active Directory basics.
- Interaction between domain machine and workstation.
- Log collection and reading.
- Small practice attacks and defenses.
- A general Windows/Ubuntu server environment.

All machines run in VirtualBox and are automatically created with the OpenTofu tool.


## Virtual Machines


| Virtual Machine | Hostname | Purpose | NIC1 | NIC2 |
|----------|----------|----------|----------|----------|
| Ansible Controller | ansible-con | Management server (Ansible) | NAT | lab-int |
| Windows Server | dc01 | Domain Controller (AD DS + DNS) | NAT | lab-int |
| Windows Client | cl01 | Client workstation (joins domain) | NAT | lab-int |
| Logging Server | log01 | Logging server | NAT | lab-int |
