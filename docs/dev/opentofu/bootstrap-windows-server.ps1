Write-Output "Starting Windows Server bootstrap..."

$Hostname = "dc01"
$User = "student"
$Pass = "Team123!"

Get-NetConnectionProfile |
Where-Object { $_.NetworkCategory -eq "Public" } |
Set-NetConnectionProfile -NetworkCategory Private

if ((hostname) -ne $Hostname) {
    Rename-Computer -NewName $Hostname -Force
}

if (-not (Get-LocalUser -Name $User -ErrorAction SilentlyContinue)) {
    net user $User $Pass /add
    net localgroup administrators $User /add
}

Enable-NetFirewallRule -Name FPS-ICMP4-ERQ-In

winrm quickconfig -q
Start-Service WinRM
Set-Service WinRM -StartupType Automatic
Start-Sleep -Seconds 5
Set-Item WSMan:\localhost\Service\Auth\Basic -Value $true
Set-Item WSMan:\localhost\Service\AllowUnencrypted -Value $true

$LangList = New-WinUserLanguageList "fi-FI"
$LangList.Add("en-US")
Set-WinUserLanguageList $LangList -Force

Set-WinSystemLocale en-US
Set-Culture en-US

Write-Output "Bootstrap completed successfully"
Start-Sleep -Seconds 5
Restart-Computer -Force
