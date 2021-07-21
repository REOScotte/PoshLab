$VMName = 'Win10'
$DVDImage = 'C:\Install\SW_DVD9_Win_Pro_Ent_Edu_N_10_1809_64-bit_English_MLF_X21-96501.ISO'

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

<#Snapshot
Stop-VM -VMName $VMName -Force
Checkpoint-VM -VMName $VMName -SnapshotName Clean
Start-VM -VMName $VMName
#>
