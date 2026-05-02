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

# ANSIBLE CONTROLLER (UBUNTU)

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
      VBoxManage modifyvm $vm --cpus 2 --memory 4096 --nic1 nat --nic2 intnet --intnet2 lab-int
      VBoxManage startvm $vm --type headless
      VBoxManage guestproperty wait $vm "/VirtualBox/GuestAdd/Version" --timeout 180000 | Out-Null

      $script=@'
#!/bin/sh
set -e

PASS="blue"

echo "Starting Ubuntu bootstrap..."

echo "$PASS" | sudo -S hostnamectl set-hostname ansible-con
echo "$PASS" | sudo -S apt update
echo "$PASS" | sudo -S apt install -y openssh-server locales
echo "$PASS" | sudo -S locale-gen en_US.UTF-8
echo "$PASS" | sudo -S update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8
echo "$PASS" | sudo -S sed -i 's/^XKBLAYOUT=.*/XKBLAYOUT="fi"/' /etc/default/keyboard
echo "$PASS" | sudo -S setupcon || true
echo "BOOTSTRAP OK at $(date)" | echo "$PASS" | sudo -S tee /tmp/bootstrap-status.txt
echo "Ubuntu bootstrap finished!"
'@

      $tmp=[System.IO.Path]::GetTempFileName()+".sh"
      Set-Content $tmp $script -Encoding ASCII

      VBoxManage guestcontrol $vm copyto $tmp --target-directory /tmp/bootstrap.sh --username "${var.ubuntu_user}" --password "${var.ubuntu_password}"
      Remove-Item $tmp -Force

      Write-Host "Running bootstrap script on guest..."
      VBoxManage guestcontrol $vm run --username "${var.ubuntu_user}" --password "${var.ubuntu_password}" --exe /bin/bash -- "" /tmp/bootstrap.sh
    PS
  }
}

# WINDOWS SERVER

resource "null_resource" "winserver_import" {
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
      VBoxManage modifyvm $vm --cpus 2 --memory 4096 --nic1 nat --nic2 intnet --intnet2 lab-int
      VBoxManage startvm $vm --type headless
      VBoxManage guestproperty wait $vm "/VirtualBox/GuestAdd/Version" --timeout 240000 | Out-Null
      Start-Sleep -Seconds 20

      $script=@'
Write-Output "Starting Windows Server bootstrap..."

$Hostname = "dc01"

Write-Output "Waiting for network identification..."
$maxWait = 60
$waited = 0
while ($waited -lt $maxWait) {
    $identifying = Get-NetConnectionProfile | Where-Object { $_.NetworkCategory -eq "Identifying" }
    if (-not $identifying) { break }
    Start-Sleep -Seconds 5
    $waited += 5
}
Get-NetConnectionProfile |
Where-Object { $_.NetworkCategory -eq "Public" } |
Set-NetConnectionProfile -NetworkCategory Private

if ((hostname) -ne $Hostname) {
    Rename-Computer -NewName $Hostname -Force
}

Write-Output "Configuring static IP 10.10.10.20/24 on internal NIC"
$intNic = Get-NetAdapter | Where-Object { $_.Status -eq "Up" } |
    Get-NetIPConfiguration | Where-Object { $_.IPv4DefaultGateway -eq $null } |
    Select-Object -First 1 -ExpandProperty InterfaceAlias

if ($intNic) {
    $existing = Get-NetIPAddress -InterfaceAlias $intNic -AddressFamily IPv4 -ErrorAction SilentlyContinue
    if ($existing) { Remove-NetIPAddress -InterfaceAlias $intNic -AddressFamily IPv4 -Confirm:$false }
    New-NetIPAddress -InterfaceAlias $intNic -IPAddress "10.10.10.20" -PrefixLength 24 -ErrorAction SilentlyContinue
    Write-Output "Static IP set on $intNic"
} else {
    Write-Output "WARNING: Could not find internal NIC"
}

Enable-NetFirewallRule -Name FPS-ICMP4-ERQ-In

winrm quickconfig -q
Start-Service WinRM
Set-Service WinRM -StartupType Automatic
Start-Sleep -Seconds 5
Set-Item WSMan:\localhost\Service\Auth\Basic -Value $true
Set-Item WSMan:\localhost\Service\AllowUnencrypted -Value $true

Set-WinUILanguageOverride -Language fi-FI
Set-WinUserLanguageList "fi-FI" -Force
Set-WinSystemLocale fi-FI
Set-Culture fi-FI

Write-Output "Bootstrap completed successfully"
Start-Sleep -Seconds 5
Restart-Computer -Force
'@

      $tmp=[System.IO.Path]::GetTempFileName()+".ps1"
      Set-Content $tmp $script -Encoding UTF8

      VBoxManage guestcontrol $vm copyto $tmp --target-directory C:\\Windows\\Temp\\bootstrap.ps1 --username "${var.windows_server_user}" --password "${var.windows_server_password}"
      Remove-Item $tmp -Force

      Write-Host "Running bootstrap script on guest..."
      VBoxManage guestcontrol $vm run --exe "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" --username "${var.windows_server_user}" --password "${var.windows_server_password}" --wait-stdout --wait-stderr -- powershell -ExecutionPolicy Bypass -File "C:\Windows\Temp\bootstrap.ps1"
    PS
  }
}

# WINDOWS CLIENT

resource "null_resource" "winclient_import" {
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
      VBoxManage modifyvm $vm --cpus 2 --memory 4096 --nic1 nat --nic2 intnet --intnet2 lab-int
      VBoxManage startvm $vm --type headless
      VBoxManage guestproperty wait $vm "/VirtualBox/GuestAdd/Version" --timeout 240000 | Out-Null
      Start-Sleep -Seconds 20

      $script=@'
Write-Output "Starting Windows Client bootstrap..."

$Hostname = "cl01"

Write-Output "Waiting for network identification..."
$maxWait = 60
$waited = 0
while ($waited -lt $maxWait) {
    $identifying = Get-NetConnectionProfile | Where-Object { $_.NetworkCategory -eq "Identifying" }
    if (-not $identifying) { break }
    Start-Sleep -Seconds 5
    $waited += 5
}
Get-NetConnectionProfile |
Where-Object { $_.NetworkCategory -eq "Public" } |
Set-NetConnectionProfile -NetworkCategory Private

if ((hostname) -ne $Hostname) {
    Write-Output "Renaming computer to $Hostname"
    Rename-Computer -NewName $Hostname -Force
} else {
    Write-Output "Hostname already correct"
}

Write-Output "Configuring static IP 10.10.10.30/24 on internal NIC"
$intNic = Get-NetAdapter | Where-Object { $_.Status -eq "Up" } |
    Get-NetIPConfiguration | Where-Object { $_.IPv4DefaultGateway -eq $null } |
    Select-Object -First 1 -ExpandProperty InterfaceAlias

if ($intNic) {
    $existing = Get-NetIPAddress -InterfaceAlias $intNic -AddressFamily IPv4 -ErrorAction SilentlyContinue
    if ($existing) { Remove-NetIPAddress -InterfaceAlias $intNic -AddressFamily IPv4 -Confirm:$false }
    New-NetIPAddress -InterfaceAlias $intNic -IPAddress "10.10.10.30" -PrefixLength 24 -ErrorAction SilentlyContinue
    Write-Output "Static IP set on $intNic"
} else {
    Write-Output "WARNING: Could not find internal NIC"
}

Enable-NetFirewallRule -Name FPS-ICMP4-ERQ-In

Write-Output "Disabling autologin"
reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v AutoAdminLogon /f
reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v DefaultUserName /f
reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v DefaultPassword /f

Write-Output "Configuring language (EN) and keyboard (FI)"

Set-WinUILanguageOverride -Language fi-FI
Set-WinUserLanguageList "fi-FI" -Force
Set-WinSystemLocale fi-FI
Set-Culture fi-FI

Write-Output "Bootstrap completed"

Start-Sleep -Seconds 5
Restart-Computer -Force
'@

      $tmp=[System.IO.Path]::GetTempFileName()+".ps1"
      Set-Content $tmp $script -Encoding UTF8

      VBoxManage guestcontrol $vm copyto $tmp --target-directory C:\\Windows\\Temp\\bootstrap.ps1 --username "${var.windows_client_user}" --password "${var.windows_client_password}"
      Remove-Item $tmp -Force

      Write-Host "Running bootstrap script on guest..."
      VBoxManage guestcontrol $vm run --exe "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" --username "${var.windows_client_user}" --password "${var.windows_client_password}" --wait-stdout --wait-stderr -- powershell -ExecutionPolicy Bypass -File "C:\Windows\Temp\bootstrap.ps1"
    PS
  }
}
