# Prepare-ansible-controller.ps1
$ErrorActionPreference = "Stop"

# Existing VirtualBox VM
$ControllerVM = "Ansible-Controller"
$VmUser = "student"
$VmPassword = "blue"

# GitHub repo
$RepoUrl = "https://github.com/tommi-vsalo/BlueTeamLab.git"

# Paths inside ansible-controller VM
$TempRepoDir = "/home/$VMUser/BlueTeamLab-temp"
$TargetDir = "/home/$VMUser/ansible-controller"
$InventoryDir = "$TargetDir/inventory"
$PlaybookDir = "$TargetDir/playbooks"

# Lab values
$DomainControllerName = "dc01"
$DomainControllerIP = "10.10.10.10"

$ClientName = "cl01"
$ClientIP = "10.10.10.20"

$WindowsUser = "student"
$WindowsPassword = "Team123!"

function Invoke-VM {
    param (
        [string]$Command
    )

    VBoxManage guestcontrol $ControllerVM run `
        --username $VmUser `
        --password $VmPassword `
        --exe /usr/bin/bash `
        -- "-lc" "$Command"

    if ($LASTEXITCODE -ne 0) {
        throw "Command failed inside VM: $Command"
    }
}

Write-Host "Preparing Ansible controller"

Write-Host "Checking if Ansible is already installed"

$AnsibleCheck = Invoke-VM "if command -v ansible >/dev/null 2>&1; then echo 'ANSIBLE_OK'; else echo 'ANSIBLE_MISSING'; fi"

if ($AnsibleCheck -match "ANSIBLE_OK") {
    Write-Host "All good. Ansible is already installed."
    Write-Host "Assuming inventory and playbooks are already present."
    exit 0
}

Write-Host "Ansible missing. Continuing setup"

Write-Host "Installing git"
Invoke-VM "sudo apt update && sudo apt install -y git"

Write-Host "Cloning BlueTeamLab repo temporarily"
Invoke-VM "rm -rf '$TempRepoDir' && git clone '$RepoUrl' '$TempRepoDir'"

Write-Host "Running bootstrap_ansible.sh"
Invoke-VM "cd '$TempRepoDir/docs/dev/ansible' && chmod +x bootstrap_ansible.sh && ./bootstrap_ansible.sh"

Write-Host "Creating directory structure"
Invoke-VM "mkdir -p '$InventoryDir' '$PlaybookDir'"

Write-Host "Copying playbooks"
Invoke-VM "cp '$TempRepoDir/docs/dev/ansible/Step_1_domain-controller.yml' '$PlaybookDir/'"
Invoke-VM "cp '$TempRepoDir/docs/dev/ansible/Step_2_domain-join.yml' '$PlaybookDir/'"
Invoke-VM "cp '$TempRepoDir/docs/dev/ansible/Step_3_ad_config.yml' '$PlaybookDir/'"

Write-Host "Creating hosts.ini"

$HostsIni = @"
[windows]
$DomainControllerName ansible_host=$DomainControllerIP
$ClientName ansible_host=$ClientIP

[windows:vars]
ansible_user=$WindowsUser
ansible_password=$WindowsPassword
ansible_connection=winrm
ansible_winrm_transport=ntlm
ansible_winrm_server_cert_validation=ignore
"@

$EscapedHostsIni = $HostsIni.Replace("'", "'\''")

Invoke-VM "cat > '$InventoryDir/hosts.ini' << 'EOF'
$EscapedHostsIni
EOF"

Invoke-VM "rm -rf '$TempRepoDir'"

Write-Host "Ansible controller is ready."
Write-Host ""
Write-Host "Created structure:"
Write-Host "~/ansible-controller/"
Write-Host "~/ansible-controller/inventory/hosts.ini"
Write-Host "~/ansible-controller/playbooks/"
Write-Host ""
