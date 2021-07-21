if (-not (Get-VMSwitch -Name Lab -ErrorAction SilentlyContinue )) {
    New-VMSwitch -Name Lab -SwitchType Private
}

$VMName = 'Router'
$DVDImage = 'C:\Users\scott\OneDrive\Downloads\Server_2022_20348.1.210507-1500.fe_release_SERVER_EVAL_x64FRE_en-us.iso'

$VM = @{
    Name               = $VMName
    MemoryStartupBytes = 1GB
    Generation         = 2
    NewVHDPath         = "C:\Users\Public\Documents\Hyper-V\Virtual hard disks\$VMName\$VMName.vhdx"
    NewVHDSizeBytes    = 40GB
    SwitchName         = 'Default Switch'
}

New-VM @VM

Add-VMDvdDrive -VMName $VMName  -Path $DVDImage
Add-VMNetworkAdapter -VMName $VMName -SwitchName Lab

Set-VMFirmware -VMName $VMName -BootOrder @(
    Get-VMHardDiskDrive -VMName $VMName
    Get-VMDvdDrive -VMName $VMName
)

Start-VM -VMName $VMName

#Set-DisplayResolution -Width 1152 -Height 864 -Force
if (-not [console]::NumberLock) {(New-Object -ComObject WScript.Shell).SendKeys('{NUMLOCK}')}
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name Shell -Value 'PowerShell.exe -NoExit'
Rename-Computer Router

Get-NetAdapter "Ethernet" | Rename-NetAdapter -NewName External
Get-NetAdapter "Ethernet 2" | Rename-NetAdapter -NewName Internal

#New-NetIPAddress -InterfaceAlias External -IPAddress 10.12.0.25 -PrefixLength 20 -DefaultGateway 10.12.0.1
New-NetIPAddress -InterfaceAlias Internal -IPAddress 192.168.0.254 -PrefixLength 24

#Set-DnsClientServerAddress -InterfaceAlias External -ServerAddresses ("208.67.222.222")

Install-WindowsFeature Routing -IncludeManagementTools -Restart
<#Reboot#>

New-Item -ItemType Directory C:\Save
New-SmbShare -Path C:\Save -Name Save -FullAccess Everyone

#Invoke-WebRequest http://download.windowsupdate.com/c/msdownload/update/software/crup/2018/05/windows10.0-kb4132216-x64_9cbeb1024166bdeceff90cd564714e1dcd01296e.msu -OutFile C:\Save\KB4132216.msu
#Invoke-WebRequest http://download.windowsupdate.com/d/msdownload/update/software/secu/2018/09/windows10.0-kb4457131-x64_a4b53b04e7398bd10fbfbb54df4ae6e10b877d22.msu -OutFile C:\Save\KB4457131.msu
#Invoke-WebRequest https://download.microsoft.com/download/B/E/D/BED73AAC-3C8A-43F5-AF4F-EB4FEA6C8F3A/ENU/x64/sqlncli.msi -OutFile C:\Save\sqlncli.msi
#Start-Process -Wait C:\Save\KB4132216.msu /quiet
#Start-Process -Wait C:\Save\KB4457131.msu /quiet
<#Reboot#>

. C:\Save\Install-Updates.ps1

Install-RemoteAccess -VpnType Vpn

$ExternalInterface = "External"
$InternalInterface = "Internal"

cmd.exe /c "netsh routing ip nat install"
cmd.exe /c "netsh routing ip nat add interface $ExternalInterface"
cmd.exe /c "netsh routing ip nat set interface $ExternalInterface mode=full"
cmd.exe /c "netsh routing ip nat add interface $InternalInterface"

Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\Terminal Server'-Name "fDenyTSConnections" -Value 0
Enable-NetFirewallRule -DisplayGroup "Remote Desktop"

$WUSettings = (New-Object -ComObject "Microsoft.Update.AutoUpdate").Settings
$WUSettings.NotificationLevel = 4
$WUSettings.Save()
# Wait for .Net Optimization service to run
<#Snapshot
Stop-VM -VMName $VMName -Force
Checkpoint-VM -VMName $VMName -SnapshotName Clean
Start-VM -VMName $VMName
#>
