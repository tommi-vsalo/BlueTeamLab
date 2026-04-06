# User Guide for BlueTeamLab

## What is the purpose of this lab?

This lab a training environment where students can explore and test:
- Windows Active Directory basics.
- Interaction between domain machine and workstation.
- Log collection and reading.
- Small practice attacks and defenses.
- A general Windows/Ubuntu server environment.
- Infrastructure-as-Code using OpenTofu.

All machines run in VirtualBox and are automatically created with the OpenTofu tool.


## Virtual Machines

The lab contains 4 machines, each with its own role.


| Virtual Machine | Hostname | Purpose | NIC1 | NIC2 |
|----------|----------|----------|----------|----------|
| Ansible Controller | ansible-con | Management server (Ansible) | NAT | lab-int |
| Windows Server | dc01 | Domain Controller (AD DS + DNS) | NAT | lab-int |
| Windows Client | cl01 | Client workstation (joins domain) | NAT | lab-int |
| Logging Server | log01 | Logging server | NAT | lab-int |


## Prerequisites

Install the following tools:

- **VirtualBox 7.2.6**
- **VBoxManage** (bundled with VirtualBox)
- **OpenTofu** (Terraform-compatible IaC tool)
- **PowerShell** (Windows host recommended)


## How to start the lab?

### Step 1
Create a folder for the lab. The image shows the folder structure.

<img width="517" height="451" alt="image" src="https://github.com/user-attachments/assets/26d6f397-3926-472a-a4bc-514a68e66ab5" />

### Step 2
Upload the OVA images and save them in the images folder.

### Step 3
Open Powershell as admin.

### Step 4
Navigate to the lab folder.
```
cd lab
```

### Step 5
Initialize OpenTofu.
```
tofu init
```

### Step 6
Create all Virtual Machines.
```
tofu apply
```

Opentofu will do the following:
- Import all OVA images.
- Create VMs in VirtualBox.
- Configure CPU, RAM, VRAM.
- Add NAT + lab-int network adapters.
- Assign VM names.
- Ensure reproducible infrastructure.


## Login Credentials

### Ansible & Logging (= Ubuntu virtual machines)
User: student
Password: team


### Server & Client (= Windows virtual machines)
User: student
Password: Team123!


## How to end the lab?

To end the lab, enter the command
```
tofu destroy
```

This unregisters and deletes all VirtualBox machines.


## Troubleshooting

### Virtual Machine doesn't import?
Check that images exist:

<img width="382" height="586" alt="image" src="https://github.com/user-attachments/assets/bdc1b5e9-a2c2-4acf-8867-b8b8f7949069" />


### Clients can't find domain?
DNS must point to dc01 = 10.10.10.10

If necessary, run:
```
ipconfig /flushdns
```


### Networking broken after import
1. Restart VirtualBox
2. Ensure lab-int exists
3. Verify NIC order (NAT first, Internal second)
