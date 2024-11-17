$config = . .\LabConfig.ps1

$config.Keys | ForEach-Object {
    New-Variable -Name $_ -Value $config.$_ -Force
}

$PublicNetwork = [ipaddress]($PublicRouterIP.Address -band $PublicRouterSubnetMask.Address)

# Create Public VM Switch
$allVMSwitches = Get-VMSwitch
$existingPublicVMSwitch = $allVMSwitches | Where-Object Name -EQ $config.PublicVMSwitchName
if (-not $existingPublicVMSwitch) {
    if ($allVMSwitches) {}
    $existingPublicVMSwitch = New-VMSwitch -Name $config.PublicVMSwitchName -NetAdapterName $config.PhysicalAdapterName -AllowManagementOS $true
}

