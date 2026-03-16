## 1. Building a VirtualBox lab using OpenTofu

The goal was to automatically set up:
- Ansible Controller (Ubuntu)
- Logging Server (Ubuntu)
- Windows Server (dc01)
- Windows Client (cl01)

From just two OVA files:
*test machine.ova (Ubuntu)*
*test machine.ova (Windows)*

This is where everything went wrong...


## 2. Baking static IP addresses for .OVA files.

While baking, I noticed that in Linux, IP addresses are in netplan files, which are literally baked into the OVA image.
→ If the same OVA is used for two roles, both get the same IP.
→ This is why the Logging Server woke up again and again with the Ansible IP.

At the same time, I caused a couple of small technical crises, such as:
- VM “machine locked” states in VirtualBox.
- Guest Additions was not running → guestcontrol was not working.
- secrets.tfvars was actually secrets.tfvars.txt.
- The test machine didn’t even have a lab-int NIC.
- netplan chose the wrong connector.


## 3. How did I solve the problem?

One Ubuntu OVA can NOT be two different roles if IPs need to be baked in. So I made two Ubuntu OVAs!

### testikone-ansible
Contains:
enp0s8 → 10.10.10.10/24

hostname → ansible-con


### testikone-logging
Contains:
enp0s8 → 10.10.10.40/24

hostname → log01



## 5. The end result
OpenTofu no longer has to fight with netplan because:

Ansible → IP inside OVA
Logging → IP inside OVA
Windows Server → baked
Windows Client → provisioning
