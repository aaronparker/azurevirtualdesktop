$Location = "australiaeast"
$Date = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
$Tags = @{
    Application    = "Azure Virtual Desktop"
    LastUpdateBy   = "aaronparker@cloud.stealthpuppy.com"
    LastUpdateDate = $Date
    Criticality    = "Medium"
    Environment    = "Production"
    Function       = "Create a virtual network"
}

$params = @{
    ResourceGroupName    = "rg-Dev-TemplateSpecs-aue"
    Name                 = "New-VirtualNetwork"
    DisplayName          = "Create a new virtual network"
    Description          = "Create a virtual network with subnets, an NSG and a NAT gateway to support AVD and Windows 365."
    Version              = "1.8"
    Location             = $Location
    TemplateFile         = $(Get-ChildItem -Path $PWD -Recurse -Include "main.bicep").FullName
    UIFormDefinitionFile = $(Get-ChildItem -Path $PWD -Recurse -Include "uiFormDefinition.json").FullName
    Tag                  = $Tags
    Force                = $true
    Verbose              = $true
}
New-AzTemplateSpec @params

# az ts create `
#     --resource-group "rg-Dev-TemplateSpecs-aue" `
#     --name "WindowsServer-vm" `
#     --display-name "Windows Server 2022" `
#     --description "Windows Server 2022 virtual machine for infrastructure workloads." `
#     --version "1.2.6" `
#     --location "$LOCATION" `
#     --template-file ./main.bicep `
#     --ui-form-definition ./uiFormDefinition.json `
#     --tags Application="Windows Server" LastUpdateBy=$UPN LastUpdateDate=$Date Criticality='Medium' Environment='Lab' Function='Virtual machine template' `
#     --yes
