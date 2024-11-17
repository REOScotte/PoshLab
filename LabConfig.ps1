@{
    ServerISOPath          = 'C:\Install\26100.1742.240906-0331.ge_release_svc_refresh_SERVER_EVAL_x64FRE_en-us.iso'
    PrivateIPNetwork       = '10.0.0.0/24'

    PublicVMSwitchName     = 'Externals'
    PrivateVMSwitchName    = 'PoshLab'

    PhysicalAdapterName    = 'Wi-Fi'
    PublicRouterIP         = [ipaddress]'192.168.0.200'
    PublicRouterSubnetMask = [ipaddress]'255.255.255.0'

    ExternalDNSServer      = '8.8.8.8'
}