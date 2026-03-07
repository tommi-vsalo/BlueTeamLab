# Prototype Testing Documentation
This document records the steps taken to test the environment in practice. The tests were done on a Windows host.

## Environment Setup

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

The Windows image worked immediately upon booting, while the Ubuntu image initially showed a black screen. This was fixed by switching from `VMSVGA` to `VBoxSVGA` in the display settings. The performance on the Ubuntu machine was initially very poor, until I inserted guest additions and updates & upgrades.

Many quality of life features should be baked into the images, like Finnish keyboard, bidirectional clipboard, guest additions etc.

## OpenTofu Questions

The following list contains questions that should be answered for the prototype stage:

- Where should the `.OVA` -images be stored so that the user can download them easily?
- What should the images exactly contain (Static IP, WinRM etc.) --> this will be answered during Ansible testing.
- What kind of documentation does the user need to provision the machines on their host (Windows, Linux)?
- Are there any manual setting up stages that can be removed prior to release?
