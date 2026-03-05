terraform {
  required_providers {
    null = { source = "hashicorp/null" }
  }
}

provider "null" {}


locals {
  ubuntu_ova  = replace(abspath("${path.module}/images/testikone.ova"), "\\", "/")
  windows_ova = replace(abspath("${path.module}/images/konetesti.ova"), "\\", "/")
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
    ova  = local.ubuntu_ova
  }

  provisioner "local-exec" {
    interpreter = ["powershell", "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command"]
    command     = local.import_ps
    environment = {
      NAME = "Ansible-Controller"
      OVA  = local.ubuntu_ova
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
    ova  = local.ubuntu_ova
  }

  provisioner "local-exec" {
    interpreter = ["powershell", "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command"]
    command     = local.import_ps
    environment = {
      NAME = "Logging-Server"
      OVA  = local.ubuntu_ova
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
    ova  = local.windows_ova
  }

  provisioner "local-exec" {
    interpreter = ["powershell", "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command"]
    command     = local.import_ps
    environment = {
      NAME = "Windows-Server"
      OVA  = local.windows_ova
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
    ova  = local.windows_ova
  }

  provisioner "local-exec" {
    interpreter = ["powershell", "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command"]
    command     = local.import_ps
    environment = {
      NAME = "Windows-Client"
      OVA  = local.windows_ova
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
    when        = destroy
    interpreter = ["powershell", "-NoProfile", "-ExecutionPolicy", "Bypass", "-Command"]
    command     = <<-PS
      $name = "Windows-Client"
      & VBoxManage unregistervm "$name" --delete
      exit 0
    PS
  }
}
