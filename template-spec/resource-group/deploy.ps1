#Requires -Module Az.Resources, Az.Accounts

$Location = "australiaeast"
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
    ResourceGroupName    = "rg-Dev-TemplateSpecs-aue"
    Name                 = "New-AvdResourceGroups"
    DisplayName          = "Create a single resource group"
    Description          = "Create a single resource group with naming conventions and tags."
    Version              = "1.0.0"
    Location             = $Location
    TemplateFile         = $(Get-ChildItem -Path $PWD -Recurse -Include "main.bicep").FullName
    UIFormDefinitionFile = $(Get-ChildItem -Path $PWD -Recurse -Include "uiFormDefinition.json").FullName
    Tag                  = $Tags
    Force                = $true
    Verbose              = $true
}
New-AzTemplateSpec @params
