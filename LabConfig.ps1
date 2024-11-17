@{
    ServerISOPath          = 'C:\Install\26100.1742.240906-0331.ge_release_svc_refresh_SERVER_EVAL_x64FRE_en-us.iso'
    PrivateIPNetwork       = '10.0.0.0/24'
    PublicRouterIP         = [ipaddress]'192.168.0.200'
    PublicRouterSubnetMask = [ipaddress]'255.255.255.0'
    PublicVMSwitchName     = 'External'
    PrivateVMSwitchName    = 'PoshLab'
    PhysicalAdapterName    = 'Ethernet'
}