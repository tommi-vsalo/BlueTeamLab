# WinRM setup
Before Ansible can connect using WinRM, the Windows host must have a WinRM listener configured. This listener will listen on the configured port and accept incoming WinRM requests.

These code snippets opens a new listener for winrm
```bash
$listenerParams = @{
    Path      = 'WSMan:\localhost\Listener'
    Address   = '*'
    Enabled   = $true
    Port      = 5985
    Transport = 'HTTP'
    Force     = $true
}
New-Item @listenerParams
```

This will now open the port 5985 to listen for ansible

After running now run: 
```bash
winrm enumerate winrm/config/listener
```
```bash
Test-WSMan
```

if you see: 

Transport=Enabled
Port=5985
ListeningOn="ip addr of computer"

Everything is right and it will work with ansible

---

source: https://docs.ansible.com/projects/ansible/latest/os_guide/windows_winrm.html#windows-winrm


