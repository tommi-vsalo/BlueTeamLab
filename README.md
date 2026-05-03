# BlueTeamLab

## What is the purpose of this lab?

This lab is a training environment where students and other interested parties can explore and test:
- Windows Active Directory basics
- Interactive lab environment
- Working with Windows and Ubuntu virtualmachines
- Infrastructure-as-Code using OpenTofu and Ansible.

The project utilizes **OpenTofu** and **Ansible** to create an lab environment in **VirtualBox** quickly, and with minimal manual effort.


## Virtual Machines

The lab contains 3 machines, each with their own roles. They are connected through an internal network and can access the internet through NAT.


| Virtual Machine | Hostname | Purpose | NIC1 | NIC2 |
|----------|----------|----------|----------|----------|
| Ansible Controller | ansible-con | Ansible control node | NAT | lab-int |
| Windows Server | dc01 | Domain Controller | NAT | lab-int |
| Windows Client | cl01 | Client workstation | NAT | lab-int |


## Prerequisites

Ensure you have the following tools on your Windows host machine:

- **VirtualBox 7.2.6**
- **VBoxManage** (bundled with VirtualBox)
- **OpenTofu** (Terraform-compatible IaC tool)

Next, install the three OVA machine images. They can be publically accessed at: [Download OVA images from OneDrive](https://haagahelia-my.sharepoint.com/:f:/g/personal/bhi059_myy_haaga-helia_fi/IgAnyOxskC_LRZZHm030ZCBJAduVs5JJIdX-yw8xf-fHfWI?e=g3pair)

Alternatively you can create your own OVA-images with the following instructions:

- Download the necessary ISO / LTS files (Windows Server 2022, Windows 10 Evaluation, Ubuntu 24.04)
- Use VirtualBox unattended installation to create VMs with guest additions and usernames / passwords
- Export the VMs as OVAs

Finally, install the most recent **release** from the BlueTeamLab GitHub page. This takes the form of a zip-file, which forms the project home directory *./BlueTeamLab*. The zip-file contains all necessary configuration files for the lab. The zip-file also contains a **README** file, which will guide the provisioning and use of the lab.


## Note
This lab is provided for **educational use only**.
The user guide is iteratively improved during the prototype phase.

## Licensing

This project is intended for **educational and testing purposes only**.

### Windows Server
Windows Server is deployed using the official **Microsoft Windows Server 2022 Evaluation** edition.
The virtual machine is intended for educational and testing purposes only and is not used in production.
The evaluation license is for a limited time.

### Windows Client
The Windows Client virtual machine is based on **Windows 10 Pro**.
The system is used without activation for educational purposes.
Commercial use is not intended. Users are responsible for complying
with Microsoft's licensing terms in their own environment.

### Ansible-Controller & Logging-Server
Ubuntu Server is distributed under open source licenses.
The software is free to use for educational purposes.

### VirtualBox & Guest Additions
The lab environment uses **Oracle VirtualBox 7.2.6**.
VirtualBox Guest Additions are installed on the virtual machines to improve graphics, networking, and host-guest integration.
Guest Additions are used under the **VirtualBox Personal Use and Evaluation License (PUEL)** for educational and testing purposes only.
