# User Guide for BlueTeamLab

## What is the purpose of this lab?

This lab a training environment where students can explore and test:
- Windows Active Directory basics.
- Interaction between domain machine and workstation.
- Log collection and reading.
- Small practice attacks and defenses.
- A general Windows/Ubuntu server environment.
- Infrastructure-as-Code using OpenTofu.
- How virtual machines are deployed automatically using VirtualBox + OVA images

All machines run in **VirtualBox** and are automatically created with the **OpenTofu** tool.


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

Create a project folder and make sure it looks like this:

<img width="517" height="451" alt="image" src="https://github.com/user-attachments/assets/26d6f397-3926-472a-a4bc-514a68e66ab5" />

### Important note for Windows users!
If OpenTofu fails and gives a `VBoxManage` error, VirtualBox may not be in your system path.

If this happens:
- Open **System Preferences**
- Go to **Advanced System Settings**
- Open **Environment Variables**
- Add the VirtualBox installation directory to your PATH
- Restart PowerShell after making the changes

This is a known issue on some Windows systems.



## How to start the lab?

### Step 1 (OVA images are not yet in public distribution!!!)
Upload the OVA images and save them in the images folder.

### Step 2
Open Powershell as admin.

### Step 3
Navigate to the lab folder.
```
cd lab
```

### Step 4
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


## Quick Test Checklist

### Infrastructure
- [ ] OpenTofu executes `tofu apply` without errors
- [ ] All four virtual machines are visible in VirtualBox
- [ ] Network card order is correct (NIC1 = NAT, NIC2 = lab-int)

### Basic virtual machine checks
- [ ] dc01 starts successfully
- [ ] cl01 starts successfully
- [ ] ansible-con starts successfully
- [ ] log01 starts successfully

### Network
- [ ] dc01 responds to ping command from cl01
- [ ] cl01 resolves dc01 via DNS
- [ ] lab-int network is reachable between machines

### Login credentials
- [ ] User `student` can log in to all machines

### Optional (when AD is configured)
- [ ] cl01 can join the domain
- [ ] Basic AD tools are open on dc01



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


## Note
This lab is provided for **educational use only**.
The user guide is iteratively improved during the prototype phase.
