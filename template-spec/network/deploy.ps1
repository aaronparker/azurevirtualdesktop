#Requires -Module Az.Resources, Az.Accounts

$Location = "westus2"
$Date = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
$Tags = @{
    Application    = "Azure Virtual Desktop"
    LastUpdateBy   = $((Get-AzContext).Account.Id)
    LastUpdateDate = $Date
    Criticality    = "Medium"
    Environment    = "Production"
    Function       = "Create a virtual network"
}

$params = @{
    ResourceGroupName    = "rg-Prod-TemplateSpecs-wus2"
    Name                 = "New-VirtualNetwork"
    DisplayName          = "Create a new AVD virtual network"
    Description          = "Create a virtual network with subnets, an NSG and a NAT gateway to support AVD and Windows 365."
    Version              = "1.0.1"
    Location             = $Location
    TemplateFile         = $(Get-ChildItem -Path $PWD -Recurse -Include "main.bicep").FullName
    UIFormDefinitionFile = $(Get-ChildItem -Path $PWD -Recurse -Include "uiFormDefinition.json").FullName
    Tag                  = $Tags
    Force                = $true
    Verbose              = $true
}
New-AzTemplateSpec @params
