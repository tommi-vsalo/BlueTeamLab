# VARIABLES

variable "ubuntu_user"     { type = string }
variable "ubuntu_password" { type = string }

variable "windows_server_user"     { type = string }
variable "windows_server_password" { type = string }

variable "windows_client_user"     { type = string }
variable "windows_client_password" { type = string }

# LOCALS

locals {
  ip_map = {
    "Ansible-Controller" = "10.10.10.10/24"
    "Windows-Server"     = "10.10.10.20/24"
    "Windows-Client"     = "10.10.10.30/24"
  }

  ubuntu_ova1  = replace(abspath("${path.module}/images/blueteam-ansible-base.ova"), "\\", "/")
  windows_ova1 = replace(abspath("${path.module}/images/blueteam-winserver-base.ova"), "\\", "/")
  windows_ova2 = replace(abspath("${path.module}/images/blueteam-winclient-base.ova"), "\\", "/")
}

# PROVIDER

terraform {
  required_providers {
    null = { source = "hashicorp/null" }
  }
}
provider "null" {}

# COMMON IMPORT FUNCTION
# Checks if the VM already exists before importing to avoid duplicate errors.

locals {
  import_ps = <<-PS
    $name = $env:NAME
    $ova  = $env:OVA

    & VBoxManage showvminfo "$name" *> $null
    if ($LASTEXITCODE -ne 0) {
      Write-Host "Importing $name"
      & VBoxManage import "$ova" --vsys 0 --vmname "$name"
    } else {
      Write-Host "$name already exists"
    }
  PS
}

# =============================================================================
# ANSIBLE CONTROLLER (UBUNTU)
# NIC1: NAT (DHCP, internet access for apt)
# NIC2: Internal network (lab-int), static IP 10.10.10.10/24
# =============================================================================

resource "null_resource" "ansible_import" {
  provisioner "local-exec" {
    interpreter = ["powershell","-NoProfile","-ExecutionPolicy","Bypass","-Command"]
    command     = local.import_ps
    environment = {
      NAME = "Ansible-Controller"
      OVA  = local.ubuntu_ova1
    }
  }
}

resource "null_resource" "ansible_bootstrap" {
  depends_on = [null_resource.ansible_import]

  provisioner "local-exec" {
    interpreter = ["powershell","-NoProfile","-ExecutionPolicy","Bypass","-Command"]
    command = <<-PS
      $vm="Ansible-Controller"

      # Configure VM hardware and network adapters
      VBoxManage modifyvm $vm --cpus 2 --memory 4096 --nic1 nat --nic2 intnet --intnet2 lab-int
      VBoxManage startvm $vm --type headless
	    # Wait for GuestAddition connection
      VBoxManage guestproperty wait $vm "/VirtualBox/GuestAdd/Version" --timeout 180000 | Out-Null

      $script=@'
#!/bin/sh
set -e

PASS="blue"

echo "=== Ansible Controller Bootstrap ==="

# Set hostname
echo "$PASS" | sudo -S hostnamectl set-hostname ansible-con

# Install required packages
echo "$PASS" | sudo -S apt update
echo "$PASS" | sudo -S apt install -y openssh-server locales ansible python3-pip
echo "$PASS" | sudo -S pip3 install pywinrm --break-system-packages || true

# Configure locale and Finnish keyboard layout
echo "$PASS" | sudo -S locale-gen en_US.UTF-8
echo "$PASS" | sudo -S update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8
echo "$PASS" | sudo -S sed -i 's/^XKBLAYOUT=.*/XKBLAYOUT="fi"/' /etc/default/keyboard
echo "$PASS" | sudo -S setupcon || true

# Configure static IP 10.10.10.10/24 on internal NIC (NIC2/enp0s8) via netplan
# NIC1 (enp0s3) remains on DHCP for NAT internet access
echo "$PASS" | sudo -S tee /etc/netplan/99-lab.yaml > /dev/null << 'NETPLAN'
network:
  version: 2
  ethernets:
    enp0s8:
      addresses:
        - 10.10.10.10/24
NETPLAN
echo "$PASS" | sudo -S netplan apply
echo "$PASS" | sudo -S chmod 600 /etc/netplan/99-lab.yaml

echo "=== Ansible Controller Bootstrap Complete ==="
'@

      $tmp=[System.IO.Path]::GetTempFileName()+".sh"
      Set-Content $tmp $script -Encoding ASCII

      # Copy bootstrap script to guest and execute it
      VBoxManage guestcontrol $vm copyto $tmp --target-directory /tmp/bootstrap.sh --username "${var.ubuntu_user}" --password "${var.ubuntu_password}"
      Remove-Item $tmp -Force

      Write-Host "Running bootstrap script on guest..."
      VBoxManage guestcontrol $vm run --username "${var.ubuntu_user}" --password "${var.ubuntu_password}" --exe /bin/bash -- "" /tmp/bootstrap.sh

      # Create Ansible directory structure
      Write-Host "Creating Ansible directory structure..."
      VBoxManage guestcontrol $vm run --username "${var.ubuntu_user}" --password "${var.ubuntu_password}" --exe /bin/mkdir -- "" -p /home/admin/blueteamlabs/inventory
      VBoxManage guestcontrol $vm run --username "${var.ubuntu_user}" --password "${var.ubuntu_password}" --exe /bin/mkdir -- "" -p /home/admin/blueteamlabs/playbooks

      # Copy Ansible files
      Write-Host "Copying Ansible files..."
      VBoxManage guestcontrol $vm copyto "${path.module}\ansible.cfg" --target-directory /home/admin/blueteamlabs/ansible.cfg --username "${var.ubuntu_user}" --password "${var.ubuntu_password}"
      VBoxManage guestcontrol $vm copyto "${path.module}\hosts.ini" --target-directory /home/admin/blueteamlabs/inventory/hosts.ini --username "${var.ubuntu_user}" --password "${var.ubuntu_password}"
      VBoxManage guestcontrol $vm copyto "${path.module}\Step_1_domain-controller.yml" --target-directory /home/admin/blueteamlabs/playbooks/ --username "${var.ubuntu_user}" --password "${var.ubuntu_password}"
      VBoxManage guestcontrol $vm copyto "${path.module}\Step_2_domain-join.yml" --target-directory /home/admin/blueteamlabs/playbooks/ --username "${var.ubuntu_user}" --password "${var.ubuntu_password}"
      VBoxManage guestcontrol $vm copyto "${path.module}\Step_3_ad_config.yml" --target-directory /home/admin/blueteamlabs/playbooks/ --username "${var.ubuntu_user}" --password "${var.ubuntu_password}"
    PS
  }
}

# =============================================================================
# WINDOWS SERVER (Domain Controller)
# NIC1: NAT (DHCP, internet access)
# NIC2: Internal network (lab-int), static IP 10.10.10.20/24
# Hostname: dc01
# =============================================================================

resource "null_resource" "winserver_import" {
  depends_on = [null_resource.ansible_bootstrap]
  provisioner "local-exec" {
    interpreter = ["powershell","-NoProfile","-ExecutionPolicy","Bypass","-Command"]
    command     = local.import_ps
    environment = {
      NAME = "Windows-Server"
      OVA  = local.windows_ova1
    }
  }
}

resource "null_resource" "winserver_bootstrap" {
  depends_on = [null_resource.winserver_import]

  provisioner "local-exec" {
    interpreter = ["powershell","-NoProfile","-ExecutionPolicy","Bypass","-Command"]
    command = <<-PS
      $vm="Windows-Server"

      # Configure VM hardware and network adapters
      VBoxManage modifyvm $vm --cpus 2 --memory 4096 --nic1 nat --nic2 intnet --intnet2 lab-int
      VBoxManage startvm $vm --type headless

      # Wait for Guest Additions then allow Windows to finish initializing
      VBoxManage guestproperty wait $vm "/VirtualBox/GuestAdd/Version" --timeout 240000 | Out-Null
      Start-Sleep -Seconds 20

      $script=@'
Write-Output "=== Windows Server Bootstrap ==="

# 1. Set static IP on internal NIC (Ethernet 2)
Write-Output "Configuring static IP 10.10.10.20/24 on Ethernet 2..."
$existing = Get-NetIPAddress -InterfaceAlias "Ethernet 2" -AddressFamily IPv4 -ErrorAction SilentlyContinue
if ($existing) { Remove-NetIPAddress -InterfaceAlias "Ethernet 2" -AddressFamily IPv4 -Confirm:$false }
New-NetIPAddress -InterfaceAlias "Ethernet 2" -IPAddress "10.10.10.20" -PrefixLength 24

# 2. Set network profile to Private via NLM COM (must happen before WinRM config)
$nlm = [Activator]::CreateInstance([Type]::GetTypeFromCLSID('DCB00C01-570F-4A9B-8D69-199FDBA5723B'))
$nlm.GetNetworks(1) | ForEach-Object { $_.SetCategory(1) }

# 3. Enable ICMP and all WinRM firewall rules across all profiles
Enable-NetFirewallRule -Name FPS-ICMP4-ERQ-In
Get-NetFirewallRule -DisplayName "Windows Remote Management (HTTP-In)" | Enable-NetFirewallRule

# 4. Configure WinRM for Ansible
Write-Output "Configuring WinRM for Ansible..."
Start-Service WinRM
Set-Service WinRM -StartupType Automatic
winrm quickconfig -q
Set-Item WSMan:\localhost\Service\Auth\Basic -Value $true
Set-Item WSMan:\localhost\Service\AllowUnencrypted -Value $true

# 5. Set Finnish keyboard and locale
Write-Output "Configuring Finnish keyboard and locale..."
Set-WinUILanguageOverride -Language fi-FI
Set-WinUserLanguageList "fi-FI" -Force
Set-WinSystemLocale fi-FI
Set-Culture fi-FI

Write-Output "=== Windows Server Bootstrap Complete ===" 
'@

      $tmp=[System.IO.Path]::GetTempFileName()+".ps1"
      Set-Content $tmp $script -Encoding UTF8

      # Copy bootstrap script to guest and execute it
      VBoxManage guestcontrol $vm copyto $tmp --target-directory C:\\Windows\\Temp\\bootstrap.ps1 --username "${var.windows_server_user}" --password "${var.windows_server_password}"
      Remove-Item $tmp -Force

      Write-Host "Running bootstrap script on guest..."
      VBoxManage guestcontrol $vm run --exe "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" --username "${var.windows_server_user}" --password "${var.windows_server_password}" --wait-stdout --wait-stderr -- powershell -ExecutionPolicy Bypass -File "C:\Windows\Temp\bootstrap.ps1"

    PS
  }
}

# =============================================================================
# WINDOWS CLIENT (Workstation)
# NIC1: NAT (DHCP, internet access)
# NIC2: Internal network (lab-int), static IP 10.10.10.30/24
# Hostname: cl01
# =============================================================================

resource "null_resource" "winclient_import" {
  depends_on = [null_resource.ansible_bootstrap]
  provisioner "local-exec" {
    interpreter = ["powershell","-NoProfile","-ExecutionPolicy","Bypass","-Command"]
    command     = local.import_ps
    environment = {
      NAME = "Windows-Client"
      OVA  = local.windows_ova2
    }
  }
}

resource "null_resource" "winclient_bootstrap" {
  depends_on = [null_resource.winclient_import]

  provisioner "local-exec" {
    interpreter = ["powershell","-NoProfile","-ExecutionPolicy","Bypass","-Command"]
    command = <<-PS
      $vm="Windows-Client"

      # Configure VM hardware and network adapters
      VBoxManage modifyvm $vm --cpus 2 --memory 4096 --nic1 nat --nic2 intnet --intnet2 lab-int
      VBoxManage startvm $vm --type headless

      # Wait for Guest Additions then allow Windows to finish initializing
      VBoxManage guestproperty wait $vm "/VirtualBox/GuestAdd/Version" --timeout 240000 | Out-Null
      Start-Sleep -Seconds 20

      $script=@'
Write-Output "=== Windows Client Bootstrap ==="

# 1. Set static IP on internal NIC (Ethernet 2)
Write-Output "Configuring static IP 10.10.10.30/24 on Ethernet 2..."
$existing = Get-NetIPAddress -InterfaceAlias "Ethernet 2" -AddressFamily IPv4 -ErrorAction SilentlyContinue
if ($existing) { Remove-NetIPAddress -InterfaceAlias "Ethernet 2" -AddressFamily IPv4 -Confirm:$false }
New-NetIPAddress -InterfaceAlias "Ethernet 2" -IPAddress "10.10.10.30" -PrefixLength 24

# 2. Set network profile to Private via NLM COM (must happen before WinRM config)
$nlm = [Activator]::CreateInstance([Type]::GetTypeFromCLSID('DCB00C01-570F-4A9B-8D69-199FDBA5723B'))
$nlm.GetNetworks(1) | ForEach-Object { $_.SetCategory(1) }

# 3. Enable ICMP and all WinRM firewall rules across all profiles
Enable-NetFirewallRule -Name FPS-ICMP4-ERQ-In
Get-NetFirewallRule -DisplayName "Windows Remote Management (HTTP-In)" | Enable-NetFirewallRule

# 4. Configure WinRM for Ansible
Write-Output "Configuring WinRM for Ansible..."
Start-Service WinRM
Set-Service WinRM -StartupType Automatic
winrm quickconfig -q
Set-Item WSMan:\localhost\Service\Auth\Basic -Value $true
Set-Item WSMan:\localhost\Service\AllowUnencrypted -Value $true

# 5. Remove autologin registry keys left by OVA preparation
Write-Output "Disabling autologin..."
$regPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon"
Remove-ItemProperty -Path $regPath -Name "AutoAdminLogon" -ErrorAction SilentlyContinue
Remove-ItemProperty -Path $regPath -Name "DefaultUserName"  -ErrorAction SilentlyContinue
Remove-ItemProperty -Path $regPath -Name "DefaultPassword"  -ErrorAction SilentlyContinue

# 6. Set Finnish keyboard and locale
Write-Output "Configuring Finnish keyboard and locale..."
Set-WinUILanguageOverride -Language fi-FI
Set-WinUserLanguageList "fi-FI" -Force
Set-WinSystemLocale fi-FI
Set-Culture fi-FI

Write-Output "=== Windows Client Bootstrap Complete ===" 
'@

      $tmp=[System.IO.Path]::GetTempFileName()+".ps1"
      Set-Content $tmp $script -Encoding UTF8

      # Copy bootstrap script to guest and execute it
      VBoxManage guestcontrol $vm copyto $tmp --target-directory C:\\Windows\\Temp\\bootstrap.ps1 --username "${var.windows_client_user}" --password "${var.windows_client_password}"
      Remove-Item $tmp -Force

      Write-Host "Running bootstrap script on guest..."
      VBoxManage guestcontrol $vm run --exe "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" --username "${var.windows_client_user}" --password "${var.windows_client_password}" --wait-stdout --wait-stderr -- powershell -ExecutionPolicy Bypass -File "C:\Windows\Temp\bootstrap.ps1"

    PS
  }
}
