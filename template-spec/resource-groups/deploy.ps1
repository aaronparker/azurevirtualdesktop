$Location = "westus2"
$Date = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
$Tags = @{
    Application    = "Azure Virtual Desktop"
    LastUpdateBy   = $((Get-AzContext).Account.Id)
    LastUpdateDate = $Date
    Criticality    = "Medium"
    Environment    = "Production"
    Function       = "Create resource groups"
}

$params = @{
    ResourceGroupName    = "rg-Prod-TemplateSpecs-wus2"
    Name                 = "New-AvdResourceGroups"
    DisplayName          = "Create AVD resource groups"
    Description          = "Create a set of resource groups for use with Nerdio Manager and Azure Virtual Desktop."
    Version              = "1.0.6"
    Location             = $Location
    TemplateFile         = $(Get-ChildItem -Path $PWD -Recurse -Include "main.bicep").FullName
    UIFormDefinitionFile = $(Get-ChildItem -Path $PWD -Recurse -Include "uiFormDefinition.json").FullName
    Tag                  = $Tags
    Force                = $true
    Verbose              = $true
}
New-AzTemplateSpec @params
