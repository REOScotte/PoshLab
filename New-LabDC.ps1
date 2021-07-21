$VMName = 'DC'
$DVDImage = 'C:\Users\scott\OneDrive\Downloads\Server_2022_20348.1.210507-1500.fe_release_SERVER_EVAL_x64FRE_en-us.iso'

$VM = @{
    Name               = $VMName
    MemoryStartupBytes = 1GB
    Generation         = 2
    NewVHDPath         = "C:\Users\Public\Documents\Hyper-V\Virtual hard disks\$VMName\$VMName.vhdx"
    NewVHDSizeBytes    = 40GB
    SwitchName         = 'Lab'
}

New-VM @VM

Add-VMDvdDrive -VMName $VMName  -Path $DVDImage

Set-VMFirmware -VMName $VMName -BootOrder @(
    Get-VMHardDiskDrive -VMName $VMName
    Get-VMDvdDrive -VMName $VMName
)

Start-VM -VMName $VMName


Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' -Name Shell -Value 'PowerShell.exe -NoExit'

New-NetIPAddress -InterfaceAlias Ethernet -IPAddress 192.168.0.10 -PrefixLength 24 -DefaultGateway 192.168.0.254
Set-DnsClientServerAddress -InterfaceAlias Ethernet -ServerAddresses 208.67.222.222
Rename-Computer DC

New-SmbMapping -LocalPath R: -RemotePath \\router\save -UserName administrator -Password asdf1234!@#$ -Persistent $true

# Easy way to sync the I drive on startup

# Copy I drive to DC so everyone can access it.
New-Item -ItemType Directory C:\Install
New-SmbShare -Path C:\Install -Name Install -FullAccess Everyone
cmd.exe /c 'icacls c:\install /grant administrators:(OI)(CI)F /grant SYSTEM:(OI)(CI)F /grant Everyone:(OI)(CI)RX /inheritance:r'
'Robocopy.exe R:\ C:\Install /mir /mt /nfl /ndl /np' | Out-File C:\windows\system32\a.bat -Encoding ascii
$rr = @'
Robocopy.exe R:\ C:\Install /mir /mt /nfl /ndl /np
if %errorlevel%==0 c:\windows\system32\rr.bat
'@
$rr | Out-File C:\windows\system32\Rr.bat -Encoding ascii

. R:\SCCM\CleanSetup.ps1
<#Snapshot
Stop-VM -VMName $VMName -Force
Checkpoint-VM -VMName $VMName -SnapshotName Clean
Start-VM -VMName $VMName
#>

. R:\SCCM\DC_01_InstallAD.ps1

<#Auto-Reboot#>

. R:\SCCM\DC_02_InstallDHCP.ps1
. R:\SCCM\AutoLogon.ps1

<#Snapshot
Stop-VM -VMName $VMName -Force
Checkpoint-VM -VMName $VMName -SnapshotName DC
Start-VM -VMName $VMName
#>






# Stopped here building PoshLab






# https://4sysops.com/archives/certificate-server-in-server-core/
Install-WindowsFeature ADCS-Cert-Authority
Install-AdcsCertificationAuthority -Confirm:$false

<# From SCCM's Clean snapshot, do the steps below:

Install-WindowsFeature ADCS-Cert-Authority -IncludeManagementTools
. R:\SCCM\AutoLogon.ps1
. R:\SCCM\DomainJoin.ps1

Certificate Templates snapin
   Duplicate Workstation Authentication Template
   - General tab
     Template display name - SCCM PXE Client
     Template name         - SCCMPXEClient
   - Request Handling tab
     Alow private key to be exported - check
   - Subject Name tab
     Supply in the request - check

   Duplicate Workstation Authentication Template
   - General tab
     Template display name - SCCM Site Server
     Template name         - SCCMSiteServer
   - Subject Name tab
     Subject name format - Common name

   Duplicate Workstation Authentication Template
   - General tab
     Template display name - SCCM Client
     Template name         - SCCMClient
   - Subject Name tab
     Subject name format - Common name

   Duplicate Web Server Template
   - General tab
     Template display name - SCCM Web Server
     Template name         - SCCMWebServer
   - Subject Name tab
     Subject name format - DNS name

Certification Authority snapin
   Certificate Templates - Add all four templates with New Certificate Templates to Issue
#>

<# Rollback SCCM to Clean
Get-SCVirtualMachine -Name T-SCCM | Get-SCVMCheckpoint | Where-Object Name -eq 'Clean' | Remove-SCVMCheckpointTree -KeepRoot -RestoreRoot -Confirm:$false
while ((Get-SCVirtualMachine -Name T-SCCM).Status -ne 'PowerOff') {Start-Sleep 1}
Start-SCVirtualMachine -VM T-SCCM
#>

New-SmbMapping -LocalPath I: -RemotePath \\DC\Install -Persistent $true
New-SmbMapping -LocalPath R: -RemotePath \\router\save -UserName administrator -Password asdf1234!@#$ -Persistent $true
. R:\SCCM\CertificatePerms.ps1
Get-ADComputer SCCM | Remove-ADObject -Recursive -Confirm:$false

<#Snapshot
Invoke-SCVMCheckpointCreation -VM T-SCCMDC -Name PKI -Restart
#>

a
# Join SCCM servers to the domain

# Create gMSA for use by JEA_Admin
Add-KdsRootKey -EffectiveTime ((Get-Date).AddHours(-10))
$jeaGroup = New-ADGroup -Name 'JEA_Admin_Endpoints' -GroupScope Universal -GroupCategory Security -PassThru
Add-ADGroupMember -Identity $jeaGroup -Members 'DC$', 'SCCM$', 'WDS$', 'WSUS$', 'DP$'
New-ADServiceAccount JEA_Admin -PrincipalsAllowedToRetrieveManagedPassword $jeaGroup -DNSHostName JEA_Admin

# Sync I drive on logon
schtasks.exe /Create /SC ONLOGON /TN SyncIDrive /TR 'C:\windows\system32\a.bat'

<#Snapshot
Invoke-SCVMCheckpointCreation -VM T-SCCMDC -Name DomainJoined -Restart
Invoke-SCVMCheckpointCreation -VM T-SCCM -Name DomainJoined -Restart
Invoke-SCVMCheckpointCreation -VM T-SCCMWDS -Name DomainJoined -Restart
Invoke-SCVMCheckpointCreation -VM T-SCCMDP -Name DomainJoined -Restart
Invoke-SCVMCheckpointCreation -VM T-SCCMWSUS -Name DomainJoined -Restart
#>

. R:\SCCM\DC_03_SCCM.ps1

# Apply updates for SCCM

<#Snapshot SCCM
't-sccmdc', 't-sccm', 't-sccmwds', 't-sccmwsus', 't-sccmdp' | ForEach-Object {Get-SCVirtualMachine $_ | Invoke-SCVMCheckpointCreation -Name SCCM -Restart}
#>

<#
Restore SCCM and BlankDrive
Get-SCVirtualMachine | Where-Object name -in @('t-sccmdc', 't-sccm', 't-sccmwds', 't-sccmwsus', 't-sccmdp') | Get-SCVMCheckpoint | Where-Object Name -eq 'SCCM' | Restore-SCVMCheckpoint -RunAsynchronously
Get-SCVirtualMachine | Where-Object name -in @('t-sccmclient') | Get-SCVMCheckpoint | Where-Object Name -eq 'BlankDrive' | Restore-SCVMCheckpoint -RunAsynchronously
$sccmVMs | ForEach-Object { while ((Get-SCVirtualMachine -Name $_).Status -ne 'PowerOff') { Start-Sleep 1 }; Get-SCVirtualMachine -Name $_ | Start-SCVirtualMachine -RunAsynchronously }
't-sccmclient' | ForEach-Object { while ((Get-SCVirtualMachine -Name $_).Status -ne 'PowerOff') { Start-Sleep 1 }; Get-SCVirtualMachine -Name $_ | Start-SCVirtualMachine -RunAsynchronously }
#>

. R:\SCCM\DC_04_WDS.ps1

# Setup Stuff
$OS = New-CMOperatingSystemImage -Name 'Windows 10 Enterprise' -Path \\DC\Install\Win10\sources\install.wim
Set-CMOperatingSystemImage -InputObject $OS -CopyToPackageShareOnDistributionPoint $true


Invoke-Command -ComputerName DC -ScriptBlock { New-ADUser -Name SCCM_SoftwareDistro -AccountPassword (ConvertTo-SecureString 'asdf1234!@#$' -AsPlainText -Force) -Enabled $true }
Invoke-Command -ComputerName DC -ScriptBlock { New-ADOrganizationalUnit StaffComputers }


New-ADUser -Name asdfasdf -AccountPassword (ConvertTo-SecureString 'asdf1234!@#$' -AsPlainText -Force) -Enabled $true

Set-NetFirewallProfile -Profile Domain, Public, Private -Enabled False






















<#
Update unknown computer collection
Set network account
Create task sequence
deploy to all computers
distribute content
#>

<#Snapshot
Invoke-SCVMCheckpointCreation -VM T-SCCM -Name WDS -Restart
#>

. I:\SCCM\InstallWSUS.ps1

<#Snapshot
Invoke-SCVMCheckpointCreation -VM T-SCCM -Name WDS -Restart
#>
