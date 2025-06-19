$Location = "westus2"
$Date = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
$Tags = @{
    Application    = "Azure"
    LastUpdateBy   = $((Get-AzContext).Account.Id)
    LastUpdateDate = $Date
    Criticality    = "High"
    Environment    = "Production"
    Function       = "Azure template specs"
    Owner          = $((Get-AzContext).Account.Id)
}

$params = @{
    Name     = "rg-Prod-TemplateSpecs-wus2"
    Location = $Location
    Tag      = $Tags
    Force    = $true
    Verbose  = $true
}
New-AzResourceGroup @params
