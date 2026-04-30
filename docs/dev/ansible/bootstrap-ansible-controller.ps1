# bootstrap-ansible-controller.ps1
$ErrorActionPreference = "Stop"

$ControllerVM = "Ansible-Controller"
$VmUser = "student"
$VmPassword = "blue"

$RepoUrl = "https://github.com/tommi-vsalo/BlueTeamLab.git"

$TempRepoDir = "/home/$VmUser/BlueTeamLab-temp"
$TargetDir = "/home/$VmUser/ansible-controller"
$InventoryDir = "$TargetDir/inventory"
$PlaybookDir = "$TargetDir/playbooks"

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

VBoxManage guestcontrol $ControllerVM run `
    --username $VmUser `
    --password $VmPassword `
    --exe /usr/bin/bash `
    -- "-lc" "command -v ansible >/dev/null 2>&1"

if ($LASTEXITCODE -eq 0) {
    Write-Host "All good. Ansible is already installed."
    Write-Host "Assuming inventory and playbooks are already present."
    exit 0
}

Write-Host "Ansible missing. Continuing setup"

# test
Write-Host "Cloning BlueTeamLab repo temporarily"

$CloneOutput = VBoxManage guestcontrol $ControllerVM run `
    --username $VmUser `
    --password $VmPassword `
    --exe /usr/bin/bash `
    -- "-lc" "rm -rf '$TempRepoDir'; git clone '$RepoUrl' '$TempRepoDir'; if [ -d '$TempRepoDir/.git' ]; then echo 'CLONE_OK'; else echo 'CLONE_FAILED'; fi"

if ($CloneOutput -match "CLONE_OK") {
    Write-Host "Repo cloned successfully."
}
else {
    throw "Repo clone failed. Check that git is installed and the VM has internet access."
}

Write-Host "Running bootstrap_ansible.sh"
Invoke-VM "cd '$TempRepoDir/docs/dev/ansible' && chmod +x bootstrap_ansible.sh && echo '$VmPassword' | sudo -S -k -p '' ./bootstrap_ansible.sh"

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

Write-Host "Cleaning temporary repo"
Invoke-VM "rm -rf '$TempRepoDir'"

Write-Host ""
Write-Host "Ansible controller is ready."
Write-Host ""
Write-Host "Created structure:"
Write-Host "~/ansible-controller/"
Write-Host "~/ansible-controller/inventory/hosts.ini"
Write-Host "~/ansible-controller/playbooks/"
Write-Host ""
Write-Host "Playbooks were NOT executed."
