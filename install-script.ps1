param (
    [string] $ConfigFile
)

# Check if the config file exists
if (-not (Test-Path $ConfigFile)) {
    Write-Host "Config file not found: $ConfigFile"
    Exit
}

# Read the configuration from the JSON file
$config = Get-Content $ConfigFile | ConvertFrom-Json

# Server Configuration
$serverConfig = $config.ServerConfiguration
# Domain Configuration
$domainConfig = $config.DomainConfiguration
# WSUS Configuration
$wsusConfig = $config.WSUSConfiguration
# DHCP Configuration
$dhcpConfig = $config.DHCPConfiguration

# Check if the computer has already been renamed
if ($env:COMPUTERNAME -ne $serverConfig.NewComputerName) {
    # Rename the computer
    Rename-Computer -NewName $serverConfig.NewComputerName -Force
    # Configure the server's IP/MASK/GW
    New-NetIPAddress -IPAddress $serverConfig.IPAddress -InterfaceAlias "Ethernet" -PrefixLength $serverConfig.PrefixLength -DefaultGateway $serverConfig.DefaultGateway -AddressFamily IPv4 
    # Configure the server's DNS
    Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses $serverConfig.DNSAddresses
    # Disable IPv6
    Set-NetAdapterBinding -Name "Ethernet" -ComponentID ms_tcpip6 -Enabled $false
    # Rename the network adapter
    Rename-NetAdapter -Name "Ethernet" -NewName $serverConfig.NewAdapterName
    # ?? Disable the firewall ??

    # Roles Installation
    Foreach ($Feature in $serverConfig.FeatureList) {
        if ((Get-WindowsFeature -Name $Feature).InstallState -eq "Available") {
            Write-Output "Feature $Feature will be installed now !"
            Try {
                Add-WindowsFeature -Name $Feature -IncludeManagementTools
                Write-Output "$Feature : Installation is a success !"
            } Catch {
                Write-Output "$Feature : Error during installation !"
            }
        }
    }
    # Define the parameters you want to pass to your script
    $ScriptPath = "C:\install-script.ps1"
    $ConfigFile = "C:\config.json"

    # Create an argument string that includes the script and its parameters
    $Argument = "-File `"$ScriptPath`" -Conf `"$ConfigFile`""
    # Create a scheduled task to rerun this script after renaming
    $Action = New-ScheduledTaskAction -Execute 'Powershell' -Argument $Argument
    $Trigger = New-ScheduledTaskTrigger -AtLogon
    Register-ScheduledTask -TaskName "RerunScriptAfterReboot" -Action $Action -Trigger $Trigger -RunLevel Highest

    # Restart the computer
    Restart-Computer
} else {
    # Check if the server is a domain controller
    $DCInfo = Get-ADDomainController -Discover

    if ($DCInfo.Count -lt 0) {
        

        # Configure and configure ADDS
        Write-Output "Configuring ADDS"
        $adminPwd = (ConvertTo-SecureString -AsPlainText $domainConfig.SafeModeAdministratorPassword -Force)
        $DomainConfiguration = @{
            DomainName = $domainConfig.DomainNameDNS
            DomainNetbiosName = $domainConfig.DomainNameNetbios
            DatabasePath = $domainConfig.DatabasePath
            LogPath = $domainConfig.LogPath
            SysvolPath = $domainConfig.SysvolPath
            SafeModeAdministratorPassword = $adminPwd
            InstallDns = $domainConfig.InstallDns
            NoRebootOnCompletion = $domainConfig.NoRebootOnCompletion
            Force = $domainConfig.Force
        }

        Install-ADDSForest @DomainConfiguration

        Start-Sleep -Milliseconds 2000

        Write-Output "ADDS configured !"

        Restart-Computer
    } else {

        # Configure WSUS
        Write-Output "Configuring WSUS"

        $directoryPath = Join-Path -Path $wsusConfig.HardDriveToUse -ChildPath $wsusConfig.ContentDir

        if (-not (Test-Path -Path $directoryPath -PathType Container)) {
            New-Item -Path $directoryPath -ItemType Directory
        } else {
            Write-Host "The directory $directoryPath already exists."
        }

        cd 'C:\Program Files\Update Services\Tools'

        .\WsusUtil.exe postinstall CONTENT_DIR=$directoryPath

        Start-Sleep -Milliseconds 2000

        Write-Output "WSUS configured !"

        Start-Sleep -Milliseconds 1000

        # Configure DHCP
        Write-Output "Configuring DHCP"

        # Create DHCP Security Groups
        netsh dhcp add securitygroups

        # Authorize DHCP Server in Active Directory
        Add-DhcpServerInDC -DnsName $serverConfig.NewComputerName -IPAddress $serverConfig.IPAddress

        # Notify Server Manager Post-Installation Completion
        Set-ItemProperty -Path registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\ServerManager\Roles\12 -Name ConfigurationState -Value 2

        # Set Server-Level DNS Dynamic Update Configuration
        Set-DhcpServerv4DnsSetting -ComputerName $serverConfig.NewComputerName -DynamicUpdates "Always" -DeleteDnsRRonLeaseExpiry $True

        # Configure DHCP Scopes
        # Loop through each VLAN in the dhcpConfig
        foreach ($vlanName in $dhcpConfig.PSObject.Properties.Name) {
            $vlan = $dhcpConfig.$vlanName

            # Configure DHCP Scope
            Add-DhcpServerv4Scope -Name $vlan.ScopeName -StartRange $vlan.StartRange -EndRange $vlan.EndRange -SubnetMask $vlan.SubnetMask -State $vlan.State

            # Configure DHCP Options
            Set-DhcpServerv4OptionValue -OptionID 3 -Value $vlan.DefaultGateway -ScopeName $vlan.ScopeName -ComputerName $serverConfig.NewComputerName
            Set-DhcpServerv4OptionValue -DnsDomain $domainConfig.DomainNameDNS -DnsServer $serverConfig.IPAddress -ScopeName $vlan.ScopeName
        }

        Start-Sleep -Milliseconds 2000

        Write-Output "DHCP configured !"
        # Remove the scheduled task
        Unregister-ScheduledTask -TaskName "RerunScriptAfterReboot" -Confirm:$false
    }
}
