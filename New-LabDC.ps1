Stop-VM -VMName $VMName -Force
Remove-VM -VMName $VMName -Force
$VM.NewVHDPath | Split-Path | Remove-Item -Force -Recurse

$VMName = 'DC2'
$DVDImage = 'C:\Save\2022.iso'
#$DVDImage = 'C:\Users\scott\OneDrive\Downloads\20348.169.210806-2348.fe_release_svc_refresh_SERVER_EVAL_x64FRE_en-us.iso'

New-ISOFile -source c:\save\2022 -destinationIso c:\save\2022.iso -bootFile C:\save\2022\efi\microsoft\boot\efisys_noprompt.bin -title 'Windows Server 2022 Evaluation' -force

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
