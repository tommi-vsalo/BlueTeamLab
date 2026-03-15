# Prototype ansible and WinRM configurations
---
## What i have.
Ansible-conroller 10.10.10.10
Windows Server 10.10.10.20

Ping is successfull to eachother.

---

## Ansible-setup
on ansible-conroller i run the this script:
```bash 
#!/usr/bin/env bash
set -e

sudo apt update
sudo apt install -y ansible python3-pip
python3 -m pip install --user pywinrm
ansible-galaxy collection install ansible.windows community.windows

mkdir -p ansible-controller/{playbooks,inventory}
```

This installs ansible and the required tools to use WinRm also creates the necessary directories for the machine to become a controller.

To make sure everything is installed correctly i run ```ansible --version```

---

## WinRm setup
on Windows-Server i will enable WinRM and open the port "5985" to listen for instructions from the ansible controller

To enable and start WinRm i run the following commands
```bash
Set-Service WinRM -StartupType Automatic
Start-Service WinRM
```

Next i open the port 5985 to listen for ansible with the following powershell script:

```bash
$listenerParams = @{
    Path      = 'WSMan:\localhost\Listener'
    Address   = '*'
    Enabled   = $true
    Port      = 5985
    Transport = 'HTTP'
    Force     = $true
}
New-Item @listenerParams
```

This is where i run into my first error message.

```bash
New-Item : The WS-Management service cannot perform the configuration operation. A listener with Address=* and
Transport=HTTP configuration already exists. You have to delete the existing listener first in order to be able to
create it with the same Address and Transport values.
At line:1 char:1
+ New-Item @listenerParam
+ ~~~~~~~~~~~~~~~~~~~~~~~
    + CategoryInfo          : NotSpecified: (:) [New-Item], InvalidOperationException
    + FullyQualifiedErrorId : System.InvalidOperationException,Microsoft.PowerShell.Commands.NewItemCommand
```

This was actually a positive thing because it means the port was open already now i will verify that it is open i run command ```winrm enumerate winrm/config/listener```

if it gives this answer
```bash
Listener
    Address = *
    Transport = HTTP
    Port = 5985
    Hostname
    Enabled = true
    URLPrefix = wsman
    CertificateThumbprint
    ListeningOn = 10.0.2.15, 10.10.10.20, 127.0.0.1, ::1, fe80::37b5:23e1:8c18:d6af%6, fe80::7a85:2330:617d:ff8f%12
```
we see that the correct port is open and it it listening on all ip addresses. In theory we only need it to listen on 10.10.10.20, but right now it doesent hurt that it listens on all ip addrs.

---

# Conection between computers via WinRm
On ansible-controller i verify that the port is reachable with command ```nc -vz 10.10.10.20 5985```
i got answer: 

```bash
Connection to 10.10.10.20 5985 port [tcp/*] succeeded!
```

This is what we wanted and now we have:

* installed ansible on the controller
* enabled WinRm on the client 
* verified that the port is open




