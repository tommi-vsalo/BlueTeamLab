# Prototype Testing Documentation
This document records the steps taken to test the environment in practice. The tests were done on a Windows host.

## OpenTofu Setup

I first made sure I had up to date versions of OpenTofu and VirtualBox.
<img width="593" height="70" alt="tofu_virtualbox" src="https://github.com/user-attachments/assets/36307142-1864-405f-9a89-6db7f3e65b95" />

I then downloaded the `main.tf` file, placing it in a new folder. 
<img width="614" height="104" alt="main_tf" src="https://github.com/user-attachments/assets/8d6e6a17-31de-4259-b546-3fb1e0273aec" />

Next I downloaded the `.OVA` -files which are used in the creation of the VMs. I added them to the `\images` folder.
<img width="680" height="110" alt="image" src="https://github.com/user-attachments/assets/a1c128a1-5612-473e-9efa-e5f28a6764be" />

I then opened the directory in PowerShell and initiated OpenTofu with the `tofu init` -command. I then tried to use `tofu apply` to provision the machines, but here I ran to the first problem of the day.

My Windows failed to find the `VBoxManage` -tool, as it is not included in path automatically. To fix this, I manually added it to the path via settings -> advanced system settings -> environment variables -> path. Remember to reboot PowerShell afterwards.

Now the command `tofu apply` provisioned the four machines at the starting price of 32 Gb and 8 minutes.

<img width="636" height="49" alt="image" src="https://github.com/user-attachments/assets/064b2fb0-2af1-4287-a095-9368285987ad" />

<img width="492" height="112" alt="image" src="https://github.com/user-attachments/assets/d34e8b9f-9f38-4a55-93ea-d8f6404d2105" />

Upon inspection in VirtualBox, all the VMs seem to be configured according to specifications.

<img width="1194" height="423" alt="image" src="https://github.com/user-attachments/assets/c116301f-0f83-4bd7-aa3d-2f12dacf85a5" />

The Windows image worked immediately upon booting, while the Ubuntu image initially showed a black screen. While it eventually began to work, there were many issues with it including graphical and performance glitches.

Many quality of life features should be baked into the images, like Finnish keyboard, bidirectional clipboard, guest additions etc. if possible. This reduces the amount of work the end user has to do.

### OpenTofu Questions

The following list contains questions that should be answered for the prototype stage:

- Where should the `.OVA` -images be stored so that the user can download them easily?
- What should the images exactly contain (Static IP, WinRM etc.) --> Ansible testing.
- What kind of documentation does the user need to provision the machines on their host (Windows, Linux)?
- Are there any manual setting up stages that can be removed prior to release?

## Ansible Setup

I started the Ansible testing by provisioning the new iteration of VMs. The initial `main.tf` -file lacked the new image designations, but this was quickly fixed. OpenTofu asks for the username and password upon provisioning (and removing!) which could be improved. Upon provisioning the Windows Client was still on the same image as the Server, which should be changed in the next iteration (desktop, not server). This also allows for its own static IP and hostname.

The Ubuntu server would initially boot to a black screen again. This was solved by pressing `esc` during bootup and altering the bootup with `nosplash`. This had to be made permanent after booting by editing `/etc/default/grub` with the same configuration and updating it with `sudo update-grub`

In addition, the NAT on all images was initially not working. I believe the Windows machines have the internal network IP configured to the NAT, which should be automatically acquired through DHCP. Ubuntu servers required the addition of `enp0s3: dhcp4: true` in netplan + `sudo netplan apply`. In Windows I added the correct intnet and allowed traffic through the firewall with:

`New-NetIPAddress -InterfaceAlias "Ethernet 2" -IPAddress 10.10.10.20 -PrefixLength 24`

`Enable-NetFirewallRule -Name FPS-ICMP4-ERQ-In`

After this, pinging the machines worked in both directions.

The Ubuntu server already had Finnish keyboard but also Finnish OS default, which should be English in the final build. Guest Additions didn't seem to work, but this might be impossible to do via OVA. I preferred to set IP forwarding in the NAT of the Ubuntu Server to control it via host powershell. The following article entails how:

https://medium.com/cyber-collective/virtualbox-ssh-connection-using-nat-port-forwarding-0a71474b02d9

WinRM was still out of action for my initial Ansible attempts, so I needed to allow for basic and unencrypted access on the Windows Server:

`PS C:\Users\Administrator> Set-Item -Path WSMan:\localhost\Service\Auth\Basic -Value $true`

`PS C:\Users\Administrator> Set-Item -Path WSMan:\localhost\Service\AllowUnencrypted -Value $true`

`PS C:\Users\Administrator> winrm get winrm/config/service`

I tested Ansible out with the following `hosts.ini`

```
[linux]
ansible-con ansible_connection=local

[windows]
dc01 ansible_host=10.10.10.20

[windows:vars]
ansible_connection=winrm
ansible_port=5985
ansible_winrm_transport=basic
ansible_winrm_server_cert_validation=ignore
ansible_user=Administrator
ansible_password=L48r4#123
```

### OVA Improvements
Windows Image
- Separate images for both client and server (different OS)
- Hostname works, add one to the client as well
- IP needs recofiguring with static IP on intnet instead of NAT
- Client needs its own static IP as well
- Server needs to enable traffic within the firewall, code above
- WinRM isn't fully functional in Server, code above

Ubuntu Image
- Hostname and static IP work, DHCP needs to be enabled in netplan for NAT
- SSH into the server probably doesn't need to be preconfigured
- The black screen bootup problem should be presolved, even if it might be machine dependant(?), code above
- 

General
- Usernames and passwords should be simple and standardized
- Finnish keyboard but English OS
- Images should be as close to baseline installation as possible, troubleshooting them could be a real issue
- Username and password upon provisioning?
- Guest Additions are a bit of a mystery to me

## Ansible Testing

Next, I tested out the `ansible.cfg` and `domain_controller_promotion.yml` -files. The first one is a global configuration file while the second is the first playbook of the project.

The configuration file causes an issue as it tries to force windows to use `sudo`. This was fixed by temporarily commenting out the priviledge escalation portion of the configuration file. 

Next I ran a very simple playbook to ensure this Ansible function worked in practice. I also ran the playbook with `--syntax-check` to catch issues. I disabled the `become` portion of the code since it didn't look quite right for the current Windows Server. 

<img width="803" height="413" alt="image" src="https://github.com/user-attachments/assets/c8dec7d8-4571-42d1-86f1-4b1ff3c0514e" />

With these steps in mind I ran the full playbook.

<img width="1721" height="549" alt="image" src="https://github.com/user-attachments/assets/21098af3-76be-47f3-8c42-a612f59787fc" />

The playbook passed the first two tasks but the DSRM password wasn't strong enough. I configured a safer password and tried again. At this stage I could see that the DNS was set properly and AD was downloading.

<img width="436" height="33" alt="image" src="https://github.com/user-attachments/assets/7387ed3b-19f1-44d6-8e93-77674a82892a" />

Upon the second try the configuration ran all the way to the end to "wait for reboot". This should be shorter to sooner determine if it ran succesfully, if possible. The Windows VM did reboot and upon further inspection the correct configurations seem to have been applied. I ran some commands to prove this was the case.

<img width="1571" height="1132" alt="image" src="https://github.com/user-attachments/assets/9718269e-4b54-4262-a26b-5955d18b6aa0" />

Everything else was right, but the DNS had strangely changed since I checked it in the previous stage. This could likely be solved by setting the DNS at the end of this playbook instead.

<img width="398" height="453" alt="image" src="https://github.com/user-attachments/assets/33096353-67f7-4dbc-8c7e-3c7da5b5f1f7" />

### Ansible Improvements
- Some outdated components (sudo in windows, become)
- Weak DSRM password
- Long wait for results
- DNS issue
- Microsoft.Ad collection could help over ansible_windows

## Version 2.0 Testing

This test covers the next generation of OVA's in preparation for public use following the user guide documentation.

- main.tf and the secrets file might be difficult to find without context, so they should reside in the git user directory with the rest of the project files.
- The password in the user guide for ubuntu servers doesn't match the secrets file.
- User guide still lacks the Ansible portion & port forwarding for SSH access
- SSH allows for direct copy of files onto the Ansible Controller:
  
<img width="477" height="105" alt="image" src="https://github.com/user-attachments/assets/31dd0b87-8a21-4cbd-9fd3-d8ae97bf1385" />
<img width="633" height="195" alt="image" src="https://github.com/user-attachments/assets/c63b934d-3a30-4e5f-982c-d2bf9e7f4800" />
<img width="810" height="55" alt="image" src="https://github.com/user-attachments/assets/1c3056fb-6d7e-45ec-b048-648056acf946" />


- Port forwarding --> open SSH connection --> scp files to Ansible controller --> chmod +x bootstrap ansible --> run ansible bootstrap
- Windows firewall blocks pings, otherwise connectivity is good from the getgo
- Windows also lacks Finnish keyboard
- Ansible file structure example needed:

<img width="409" height="90" alt="image" src="https://github.com/user-attachments/assets/1b7a3191-8644-45cd-8b61-787b2f148eb4" />

- ansible.cfg still uses sudo on windows, I commented out the priviledge escalation lines
- winrm configuration issues persist and hosts.ini is outdated to current configurations

<img width="639" height="486" alt="image" src="https://github.com/user-attachments/assets/b82acb8c-d634-404d-a634-3f248ac9c91a" />

- The only issue with the first playbook seems to be fine except for the weak password
- Windows Client also needs to enable PSRemoting and winrm

<img width="1132" height="329" alt="image" src="https://github.com/user-attachments/assets/1c1c73ae-3366-46d7-ad9d-cc29af549228" />

- The second playbook had initial issues, but this is where my time ran out for the day

To recap, currently the manual tasks to get the environment working are:

secrets file shows "team" as ubuntu password but its still "blue"

Winserver
- Enable-NetFirewallRule -Name FPS-ICMP4-ERQ-I
- Set-Item -Path WSMan:\localhost\Service\Auth\Basic -Value $true
- Set-Item -Path WSMan:\localhost\Service\AllowUnencrypted -Value $true

Ansible Controller
- Set portforwarding in NAT
- https://medium.com/cyber-collective/virtualbox-ssh-connection-using-nat-port-forwarding-0a71474b02d9
- Send the files in the correct ansible structure (ansible --> inventory -> hosts.ini, playbooks -> Step.yml...)
- scp -P 2222 D:\BlueFiles\* student@127.0.0.1:.
- chmod +x bootstrap_ansible.sh
- ./bootstrap_ansible.sh
- ansible windows -i inventory/hosts.ini -m win_ping

## OpenTofu Scripting

Preferring scripting to machine image based configuration would be useful in completing the infra-as-code concept of the project. The following lines should be used as a proof of concept in the OpenTofu `cloud.init`. They allow the Windows Server to communicate with the Ansible Controller.

`Enable-NetFirewallRule -Name FPS-ICMP4-ERQ-In`

`PS C:\Users\Administrator> Set-Item -Path WSMan:\localhost\Service\Auth\Basic -Value $true`

`PS C:\Users\Administrator> Set-Item -Path WSMan:\localhost\Service\AllowUnencrypted -Value $true`










