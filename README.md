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

Next, install the most recent **release** from the BlueTeamLab GitHub page. This takes the form of a zip-file, which forms the project home directory *./BlueTeamLab*. The zip-file contains all necessary configuration files for the lab.

Finally, install the three OVA. machine images. They can be accessed at:

Alternatively you can create your own OVA. images. This can easily be accomplished through an VirtualBox unattended install.


### Important note for Windows users!
If OpenTofu fails and gives a `VBoxManage` error, VirtualBox may not be in your system path.

If this happens:
- Open **System Settings**
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

### Step 5
Create all Virtual Machines.
```
tofu apply
```

Initial setup may take several minutes depending on your system.
Please expect approximately:
- 5-10 minutes of setup time
- approximately 30 GB of disk space usage

This is normal during first use.

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
- [ ] All three virtual machines are visible in VirtualBox

### Basic virtual machine checks
- [ ] dc01 starts successfully
- [ ] cl01 starts successfully
- [ ] ansible-con starts successfully

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


### Ubuntu displays a black screen on first boot

On some systems, Ubuntu virtual machines may initially display a black screen.

- This may resolve itself after a short wait.
- Guest Additions are already stored in the disk images. This reduces the amount of manual configuration required from students.
- Once the system has booted, normal operation is expected.

This does not indicate a failed installation.


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
