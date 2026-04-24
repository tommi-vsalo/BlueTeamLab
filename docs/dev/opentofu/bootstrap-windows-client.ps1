Write-Output "Starting Windows Client bootstrap..."

$Hostname = "cl01"
$User = "student"
$Pass = "Team123!"

if ((hostname) -ne $Hostname) {
    Write-Output "Renaming computer to $Hostname"
    Rename-Computer -NewName $Hostname -Force
} else {
    Write-Output "Hostname already correct"
}

if (-not (Get-LocalUser -Name $User -ErrorAction SilentlyContinue)) {
    Write-Output "Creating local admin user $User"
    net user $User $Pass /add
    net localgroup administrators $User /add
}

Write-Output "Disabling autologin"
reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v AutoAdminLogon /f
reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v DefaultUserName /f
reg delete "HKLM\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" /v DefaultPassword /f


Write-Output "Configuring language (EN) and keyboard (FI)"

$LangList = New-WinUserLanguageList "fi-FI"
$LangList.Add("en-US")
Set-WinUserLanguageList $LangList -Force

Set-WinSystemLocale en-US
Set-Culture en-US

$xml = @"
<gs:GlobalizationServices xmlns:gs="urn:longhornGlobalizationUnattend">
  <gs:UserList>
    <gs:User UserID="Current"/>
  </gs:UserList>
  <gs:InputPreferences>
    add
  </gs:InputPreferences>
</gs:GlobalizationServices>
"@

$xml | Out-File C:\lang.xml -Encoding Unicode

Start-Process control.exe -ArgumentList 'intl.cpl,,/f:"C:\lang.xml"'

Write-Output "Bootstrap completed"

Start-Sleep -Seconds 5
Restart-Computer -Force
