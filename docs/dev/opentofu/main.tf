variable "ubuntu_user"     { type = string }
variable "ubuntu_password" { type = string }
variable "windows_user"    { type = string }
variable "windows_password"{ type = string }

locals {
  ip_map = {
    "Ansible-Controller" = "10.10.10.10/24"
    "Logging-Server"     = "10.10.10.40/24"
    "Windows-Server"     = "10.10.10.20/24"
    "Windows-Client"     = "10.10.10.30/24"
  }
}

terraform {
  required_providers {
    null = { source = "hashicorp/null" }
  }
}

provider "null" {}

locals {
  ubuntu_ova1  = replace(abspath("${path.module}/images/testikone-ansible.ova"), "\\", "/")
  ubuntu_ova2  = replace(abspath("${path.module}/images/testikone-logging.ova"), "\\", "/")
  windows_ova1 = replace(abspath("${path.module}/images/konetesti-server.ova"), "\\", "/")
  windows_ova2 = replace(abspath("${path.module}/images/konetesti-client1.ova"), "\\", "/")
}


locals {
  import_ps = <<-PS
    $name = $env:NAME
    $ova  = $env:OVA

    & VBoxManage showvminfo "$name" *> $null
    if ($LASTEXITCODE -ne 0) {
      Write-Host "Importing $name ..."
      & VBoxManage import "$ova" --vsys 0 --vmname "$name"
      exit $LASTEXITCODE
    } else {
      Write-Host "$name already exists. Skipping import."
    }
  PS
}

###############################
# Ansible (Ubuntu)
###############################
resource "null_resource" "ansible" {
  triggers = {
    name = "Ansible-Controller"
    ova  = local.ubuntu_ova1
  }

  # Import
  provisioner "local-exec" {
    interpreter = ["powershell", "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command"]
    command     = local.import_ps
    environment = {
      NAME = "Ansible-Controller"
      OVA  = local.ubuntu_ova1
    }
  }

 
  provisioner "local-exec" {
    interpreter = ["powershell", "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command"]
    command = <<-PS
      $name = "Ansible-Controller"
      VBoxManage modifyvm $name --cpus 2
      VBoxManage modifyvm $name --memory 4096
      VBoxManage modifyvm $name --vram 16
      VBoxManage modifyvm $name --nic1 nat
      VBoxManage modifyvm $name --nic2 intnet
      VBoxManage modifyvm $name --intnet2 "lab-int"
    PS
  }


  provisioner "local-exec" {
    interpreter = ["powershell", "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command"]
    command = <<-PS
      $name   = "Ansible-Controller"
      $ipCidr = "${local.ip_map["Ansible-Controller"]}"

      & VBoxManage startvm "$name" --type headless
      & VBoxManage guestproperty wait "$name" "/VirtualBox/GuestAdd/Version" --timeout 180000 | Out-Null

      $script = @'
#!/bin/sh
set -eu
IPCIDR="$1"

pick_nic() {
  for nic in $(ip -o link show | awk -F': ' '$2 !~ /^lo/ {print $2}'); do
    if ip -o -4 addr show "$nic" 2>/dev/null | grep -q '10\.0\.2\.'; then
      continue
    fi
    echo "$nic"; return 0
  done
  ip -o link show | awk -F': ' '$2 !~ /^lo/ {print $2}' | head -n1
}
NIC="$(pick_nic)"

cat >/tmp/50-lab-int.yaml <<YAML
network:
  version: 2
  ethernets:
    $${NIC}:
      dhcp4: false
      addresses:
        - $${IPCIDR}
YAML

echo "${var.ubuntu_password}" | sudo -S sh -lc 'mv /tmp/50-lab-int.yaml /etc/netplan/50-lab-int.yaml && netplan apply'
'@

      $tmp = [System.IO.Path]::GetTempFileName() + ".sh"
      Set-Content -Path $tmp -Value $script -Encoding ASCII

      & VBoxManage guestcontrol "$name" copyto "$tmp" --target-directory "/tmp/set-ip.sh" --username "${var.ubuntu_user}" --password "${var.ubuntu_password}"
      & VBoxManage guestcontrol "$name" run --username "${var.ubuntu_user}" --password "${var.ubuntu_password}" --exe "/bin/sh" -- sh -lc "chmod +x /tmp/set-ip.sh && /tmp/set-ip.sh '$ipCidr'"

      Remove-Item $tmp -Force -ErrorAction SilentlyContinue
    PS
  }

  # Destroy
  provisioner "local-exec" {
    when        = destroy
    interpreter = ["powershell", "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command"]
    command     = <<-PS
      $name = "Ansible-Controller"
      & VBoxManage unregistervm "$name" --delete
      exit 0
    PS
  }
}

###############################
# Logging (Ubuntu)
###############################
resource "null_resource" "logging" {
  triggers = {
    name = "Logging-Server"
    ova  = local.ubuntu_ova2
  }

  # Import
  provisioner "local-exec" {
    interpreter = ["powershell", "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command"]
    command     = local.import_ps
    environment = {
      NAME = "Logging-Server"
      OVA  = local.ubuntu_ova2
    }
  }


  provisioner "local-exec" {
    interpreter = ["powershell", "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command"]
    command = <<-PS
      $name = "Logging-Server"
      VBoxManage modifyvm $name --cpus 2
      VBoxManage modifyvm $name --memory 4096
      VBoxManage modifyvm $name --vram 16
      VBoxManage modifyvm $name --nic1 nat
      VBoxManage modifyvm $name --nic2 intnet
      VBoxManage modifyvm $name --intnet2 "lab-int"
    PS
  }

 
  provisioner "local-exec" {
    interpreter = ["powershell", "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command"]
    command = <<-PS
      $name   = "Logging-Server"
      $ipCidr = "${local.ip_map["Logging-Server"]}"

      & VBoxManage startvm "$name" --type headless
      & VBoxManage guestproperty wait "$name" "/VirtualBox/GuestAdd/Version" --timeout 180000 | Out-Null

      $script = @'
#!/bin/sh
set -eu
IPCIDR="$1"

pick_nic() {
  for nic in $(ip -o link show | awk -F': ' '$2 !~ /^lo/ {print $2}'); do
    if ip -o -4 addr show "$nic" 2>/dev/null | grep -q '10\.0\.2\.'; then
      continue
    fi
    echo "$nic"; return 0
  done
  ip -o link show | awk -F': ' '$2 !~ /^lo/ {print $2}' | head -n1
}
NIC="$(pick_nic)"


cat >/tmp/50-lab-int.yaml <<'YAML'
network:
  version: 2
  ethernets:
    enp0s8:
      dhcp4: false
      addresses:
        - $${IPCIDR}
YAML


echo "${var.ubuntu_password}" | sudo -S sh -lc 'rm -f /etc/netplan/*.yaml && install -m 600 /tmp/50-lab-int.yaml /etc/netplan/50-lab-int.yaml && netplan apply'

'@

      $tmp = [System.IO.Path]::GetTempFileName() + ".sh"
      Set-Content -Path $tmp -Value $script -Encoding ASCII
      & VBoxManage guestcontrol "$name" copyto "$tmp" --target-directory "/tmp/set-ip.sh" --username "${var.ubuntu_user}" --password "${var.ubuntu_password}"
      & VBoxManage guestcontrol "$name" run --username "${var.ubuntu_user}" --password "${var.ubuntu_password}" --exe "/bin/sh" -- sh -lc "chmod +x /tmp/set-ip.sh && /tmp/set-ip.sh '$ipCidr'"
      Remove-Item $tmp -Force -ErrorAction SilentlyContinue
    PS
  }

  # Destroy
  provisioner "local-exec" {
    when        = destroy
    interpreter = ["powershell", "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command"]
    command     = <<-PS
      $name = "Logging-Server"
      & VBoxManage unregistervm "$name" --delete
      exit 0
    PS
  }
}

###############################
# Windows Server
###############################
resource "null_resource" "winserver" {
  triggers = {
    name = "Windows-Server"
    ova  = local.windows_ova1
  }


  provisioner "local-exec" {
    interpreter = ["powershell", "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command"]
    command     = local.import_ps
    environment = {
      NAME = "Windows-Server"
      OVA  = local.windows_ova1
    }
  }

  
  provisioner "local-exec" {
    interpreter = ["powershell", "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command"]
    command = <<-PS
      $name = "Windows-Server"
      VBoxManage modifyvm $name --cpus 2
      VBoxManage modifyvm $name --memory 4096
      VBoxManage modifyvm $name --vram 128
      VBoxManage modifyvm $name --nic1 nat
      VBoxManage modifyvm $name --nic2 intnet
      VBoxManage modifyvm $name --intnet2 "lab-int"
    PS
  }


  provisioner "local-exec" {
    interpreter = ["powershell", "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command"]
    command = <<-PS
      $name   = "Windows-Server"
      $ipCidr = "${local.ip_map["Windows-Server"]}"
      $ip, $prefix = $ipCidr.Split("/")

      & VBoxManage startvm "$name" --type headless
      & VBoxManage guestproperty wait "$name" "/VirtualBox/GuestAdd/Version" --timeout 240000 | Out-Null

      $script = @'
param([string]$ip, [int]$prefix)
$adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" -and $_.HardwareInterface }
$nat = foreach($a in $adapters){
  $v4 = Get-NetIPAddress -InterfaceIndex $a.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue
  if($v4 -and ($v4.IPAddress -like "10.0.2.*")) { $a; break }
}
$lab = ($adapters | Where-Object { $_.ifIndex -ne $nat.ifIndex } | Select-Object -First 1)
if(-not $lab){ throw "Lab interface not found." }

Get-NetIPAddress -InterfaceIndex $lab.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue |
  Remove-NetIPAddress -Confirm:$false -ErrorAction SilentlyContinue

New-NetIPAddress -InterfaceIndex $lab.ifIndex -IPAddress $ip -PrefixLength $prefix -AddressFamily IPv4
Set-NetConnectionProfile -InterfaceIndex $lab.ifIndex -NetworkCategory Private
'@

      $tmp = [System.IO.Path]::GetTempFileName() + ".ps1"
      Set-Content -Path $tmp -Value $script -Encoding UTF8
      & VBoxManage guestcontrol "$name" copyto "$tmp" --target-directory "C:\\Windows\\Temp\\set-ip.ps1" --username "${var.windows_user}" --password "${var.windows_password}"
      & VBoxManage guestcontrol "$name" run --username "${var.windows_user}" --password "${var.windows_password}" --exe "C:\\Windows\\System32\\WindowsPowerShell\\v1.0\\powershell.exe" -- powershell -NoProfile -ExecutionPolicy Bypass -File "C:\\Windows\\Temp\\set-ip.ps1" -ip "$ip" -prefix $prefix
      Remove-Item $tmp -Force -ErrorAction SilentlyContinue
    PS
  }

  # Destroy
  provisioner "local-exec" {
    when        = destroy
    interpreter = ["powershell", "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command"]
    command     = <<-PS
      $name = "Windows-Server"
      & VBoxManage unregistervm "$name" --delete
      exit 0
    PS
  }
}

###############################
# Windows Client
###############################
resource "null_resource" "winclient" {
  triggers = {
    name = "Windows-Client"
    ova  = local.windows_ova2
  }

  # Import
  provisioner "local-exec" {
    interpreter = ["powershell", "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command"]
    command     = local.import_ps
    environment = {
      NAME = "Windows-Client"
      OVA  = local.windows_ova2
    }
  }


  provisioner "local-exec" {
    interpreter = ["powershell", "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command"]
    command = <<-PS
      $name = "Windows-Client"
      VBoxManage modifyvm $name --cpus 2
      VBoxManage modifyvm $name --memory 4096
      VBoxManage modifyvm $name --vram 128
      VBoxManage modifyvm $name --nic1 nat
      VBoxManage modifyvm $name --nic2 intnet
      VBoxManage modifyvm $name --intnet2 "lab-int"
    PS
  }


  provisioner "local-exec" {
    interpreter = ["powershell", "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command"]
    command = <<-PS
      $name   = "Windows-Client"
      $ipCidr = "${local.ip_map["Windows-Client"]}"
      $ip, $prefix = $ipCidr.Split("/")

      & VBoxManage startvm "$name" --type headless
      & VBoxManage guestproperty wait "$name" "/VirtualBox/GuestAdd/Version" --timeout 240000 | Out-Null

      $script = @'
param([string]$ip, [int]$prefix)
$adapters = Get-NetAdapter | Where-Object { $_.Status -eq "Up" -and $_.HardwareInterface }
$nat = foreach($a in $adapters){
  $v4 = Get-NetIPAddress -InterfaceIndex $a.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue
  if($v4 -and ($v4.IPAddress -like "10.0.2.*")) { $a; break }
}
$lab = ($adapters | Where-Object { $_.ifIndex -ne $nat.ifIndex } | Select-Object -First 1)
if(-not $lab){ throw "Lab interface not found." }

Get-NetIPAddress -InterfaceIndex $lab.ifIndex -AddressFamily IPv4 -ErrorAction SilentlyContinue |
  Remove-NetIPAddress -Confirm:$false -ErrorAction SilentlyContinue

New-NetIPAddress -InterfaceIndex $lab.ifIndex -IPAddress $ip -PrefixLength $prefix -AddressFamily IPv4
Set-NetConnectionProfile -InterfaceIndex $lab.ifIndex -NetworkCategory Private
'@

      $tmp = [System.IO.Path]::GetTempFileName() + ".ps1"
      Set-Content -Path $tmp -Value $script -Encoding UTF8
      & VBoxManage guestcontrol "$name" copyto "$tmp" --target-directory "C:\\Windows\\Temp\\set-ip.ps1" --username "${var.windows_user}" --password "${var.windows_password}"
      & VBoxManage guestcontrol "$name" run --username "${var.windows_user}" --password "${var.windows_password}" --exe "C:\\Windows\\System32\\WindowsPowerShell\\v1.0\\powershell.exe" -- powershell -NoProfile -ExecutionPolicy Bypass -File "C:\\Windows\\Temp\\set-ip.ps1" -ip "$ip" -prefix $prefix
      Remove-Item $tmp -Force -ErrorAction SilentlyContinue
    PS
  }

  # Destroy
  provisioner "local-exec" {
    when        = destroy
    interpreter = ["powershell", "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command"]
    command     = <<-PS
      $name = "Windows-Client"
      & VBoxManage unregistervm "$name" --delete
      exit 0
    PS
  }
}
