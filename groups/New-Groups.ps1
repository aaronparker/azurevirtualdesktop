# https://learn.microsoft.com/en-us/azure/virtual-desktop/configure-single-sign-on#prerequisites

# Install modules
Install-Module Microsoft.Graph
Import-Module Microsoft.Graph.Authentication -Force
Import-Module Microsoft.Graph.Applications -Force

# Authenticate to the Microsoft Graph API
Connect-MgGraph -Scopes "Application.Read.All", "Application-RemoteDesktopConfig.ReadWrite.All" -UseDeviceCode

# Get the service principal IDs for the Windows Client and MS Remote Desktop service principals
$MSRDspId = (Get-MgServicePrincipal -Filter "AppId eq 'a4a365df-50f1-4397-bc59-1a1564b8bb9c'").Id
$WCLspId = (Get-MgServicePrincipal -Filter "AppId eq '270efc09-cd0d-444b-a71f-39af4910ec45'").Id

# Enable the Remote Desktop Protocol for the service principals
Update-MgServicePrincipalRemoteDesktopSecurityConfiguration -ServicePrincipalId $MSRDspId -IsRemoteDesktopProtocolEnabled
Update-MgServicePrincipalRemoteDesktopSecurityConfiguration -ServicePrincipalId $WCLspId -IsRemoteDesktopProtocolEnabled

# Add the service principals to the target device groups
$Groups = @("DeviceCollection-Avd-AvdHostPool-01-australiaeast",
    "DeviceCollection-Avd-AvdHostPool-02-australiaeast",
    "DeviceCollection-Avd-AvdHostPool-01-southcentralus",
    "DeviceCollection-Avd-AvdHostPool-01-uksouth")
foreach ($Group in $Groups) {
    $tdg = New-Object -TypeName "Microsoft.Graph.PowerShell.Models.MicrosoftGraphTargetDeviceGroup"
    $tdg.Id = (Get-MgGroup -Filter ("DisplayName eq '{0}'" -f $Group)).Id
    $tdg.DisplayName = $Group

    New-MgServicePrincipalRemoteDesktopSecurityConfigurationTargetDeviceGroup -ServicePrincipalId $MSRDspId -BodyParameter $tdg
    New-MgServicePrincipalRemoteDesktopSecurityConfigurationTargetDeviceGroup -ServicePrincipalId $WCLspId -BodyParameter $td
}
