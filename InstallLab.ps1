$config = . .\LabConfig.ps1

$config.Keys | ForEach-Object {
    New-Variable -Name $_ -Value $config.$_ -Force
}

# Create Public VM Switch
$existingPublicSwitch = Get-VMSwitch | Where-Object Name -EQ $config.PublicSwitchName
if (-not $existingPublicSwitch) {
    $existingPublicSwitch = New-VMSwitch -Name $config.PublicVMSwitchName -SwitchType External -NetAdapterName $config.PublicAdapterName -AllowManagementOS $false
}

