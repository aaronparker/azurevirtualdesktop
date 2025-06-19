$Location = "australiaeast"
$Date = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
$Tags = @{
    Application    = "Azure Virtual Desktop"
    LastUpdateBy   = "aaronparker@cloud.stealthpuppy.com"
    LastUpdateDate = $Date
    Criticality    = "Medium"
    Environment    = "Production"
    Function       = "Create resource groups"
}

$params = @{
    ResourceGroupName    = "rg-Dev-TemplateSpecs-aue"
    Name                 = "New-ResourceGroups"
    DisplayName          = "Create a set of resource groups"
    Description          = "Create a set of resource groups for use with Nerdio Manager and Azure Virtual Desktop."
    Version              = "1.0.5"
    Location             = $Location
    TemplateFile         = $(Get-ChildItem -Path $PWD -Recurse -Include "main.bicep").FullName
    UIFormDefinitionFile = $(Get-ChildItem -Path $PWD -Recurse -Include "uiFormDefinition.json").FullName
    Tag                  = $Tags
    Force                = $true
    Verbose              = $true
}
New-AzTemplateSpec @params
