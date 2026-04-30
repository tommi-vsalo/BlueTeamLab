# VARIABLES

variable "ubuntu_user"     { type = string }
variable "ubuntu_password" { type = string }
variable "windows_user"    { type = string }
variable "windows_password"{ type = string }

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
hostnamectl set-hostname ansible-con
apt update
apt install -y openssh-server
'@

      $tmp=[System.IO.Path]::GetTempFileName()+".sh"
      Set-Content $tmp $script -Encoding ASCII

      VBoxManage guestcontrol $vm copyto $tmp --target-directory /tmp/bootstrap.sh --username "${var.ubuntu_user}" --password "${var.ubuntu_password}"
      VBoxManage guestcontrol $vm run --username "${var.ubuntu_user}" --password "${var.ubuntu_password}" --exe /bin/bash -- bash /tmp/bootstrap.sh
      Remove-Item $tmp -Force
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

      $script=@'
Rename-Computer -NewName dc01 -Force
net user student Team123! /add
net localgroup administrators student /add
Enable-NetFirewallRule -Name FPS-ICMP4-ERQ-In
winrm quickconfig -q
Restart-Computer -Force
'@

      $tmp=[System.IO.Path]::GetTempFileName()+".ps1"
      Set-Content $tmp $script -Encoding UTF8

      VBoxManage guestcontrol $vm copyto $tmp --target-directory C:\\Windows\\Temp\\boot.ps1 --username "${var.windows_user}" --password "${var.windows_password}"
      VBoxManage guestcontrol $vm run --username "${var.windows_user}" --password "${var.windows_password}" --exe powershell.exe -- powershell -ExecutionPolicy Bypass -File C:\\Windows\\Temp\\boot.ps1
      Remove-Item $tmp -Force
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

      $script=@'
Rename-Computer -NewName cl01 -Force
net user student Team123! /add
net localgroup administrators student /add
Restart-Computer -Force
'@

      $tmp=[System.IO.Path]::GetTempFileName()+".ps1"
      Set-Content $tmp $script -Encoding UTF8
      VBoxManage guestcontrol $vm copyto $tmp --target-directory C:\\Windows\\Temp\\boot.ps1 --username "${var.windows_user}" --password "${var.windows_password}"
      VBoxManage guestcontrol $vm run --username "${var.windows_user}" --password "${var.windows_password}" --exe powershell.exe -- powershell -ExecutionPolicy Bypass -File C:\\Windows\\Temp\\boot.ps1
      Remove-Item $tmp -Force
    PS
  }
}
