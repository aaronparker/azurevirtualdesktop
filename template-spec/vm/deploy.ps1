# ================================================================================
# Deploy Windows VM Template Spec to Azure
# ================================================================================
# This script creates or updates the Template Spec in Azure

param(
    [string]$TemplateSpecName = "windows-vm-simplified",
    [string]$TemplateSpecRG = "rg-template-specs",
    [string]$TemplateSpecLocation = "eastus",
    [string]$TemplateSpecVersion = "1.0.0",
    [string]$TemplateSpecDescription = "Simplified Windows VM deployment with Key Vault integration"
)

$ErrorActionPreference = "Stop"

Write-Host "================================================================================" -ForegroundColor Green
Write-Host "Windows VM Template Spec Deployment" -ForegroundColor Green
Write-Host "================================================================================" -ForegroundColor Green
Write-Host ""

# Check if Azure PowerShell is installed
try {
    Import-Module Az.Accounts -ErrorAction Stop
    Import-Module Az.Resources -ErrorAction Stop
}
catch {
    Write-Host "Error: Azure PowerShell modules are not installed" -ForegroundColor Red
    Write-Host "Please install from: https://docs.microsoft.com/powershell/azure/install-az-ps" -ForegroundColor Yellow
    exit 1
}

# Check if logged in
Write-Host "Checking Azure login status..." -ForegroundColor Yellow
try {
    $context = Get-AzContext
    if (-not $context) {
        throw "Not logged in"
    }
    Write-Host "✓ Logged in to subscription: $($context.Subscription.Name) ($($context.Subscription.Id))" -ForegroundColor Green
}
catch {
    Write-Host "Error: Not logged into Azure" -ForegroundColor Red
    Write-Host "Please run: Connect-AzAccount" -ForegroundColor Yellow
    exit 1
}
Write-Host ""

# Create resource group for template spec
Write-Host "Creating resource group for Template Spec..." -ForegroundColor Yellow
$null = New-AzResourceGroup `
    -Name $TemplateSpecRG `
    -Location $TemplateSpecLocation `
    -Force

Write-Host "✓ Resource group ready: $TemplateSpecRG" -ForegroundColor Green
Write-Host ""

# Build the Bicep template
Write-Host "Building Bicep template..." -ForegroundColor Yellow
az bicep build --file main.bicep

Write-Host "✓ Bicep template compiled successfully" -ForegroundColor Green
Write-Host ""

# Create or update the template spec
Write-Host "Creating/updating Template Spec..." -ForegroundColor Yellow

$templateSpecParams = @{
    Name                 = $TemplateSpecName
    ResourceGroupName    = $TemplateSpecRG
    Location             = $TemplateSpecLocation
    Description          = $TemplateSpecDescription
    DisplayName          = "Windows VM - Simplified Deployment"
    Version              = $TemplateSpecVersion
    TemplateFile         = "main.bicep"
    UIFormDefinitionFile = "uiFormDefinition.json"
    VersionDescription   = "Initial release with Key Vault integration"
    Tag                  = @{
        "Type"      = "TemplateSpec"
        "OS"        = "Windows"
        "ManagedBy" = "ITOps"
    }
    Force                = $true
}

$templateSpec = New-AzTemplateSpec @templateSpecParams

Write-Host "✓ Template Spec created/updated successfully" -ForegroundColor Green
Write-Host ""

# Get Template Spec ID
$templateSpecId = $templateSpec.Versions[0].Id

Write-Host "================================================================================" -ForegroundColor Green
Write-Host "Deployment Complete!" -ForegroundColor Green
Write-Host "================================================================================" -ForegroundColor Green
Write-Host ""
Write-Host "Template Spec Details:"
Write-Host "  Name: $TemplateSpecName"
Write-Host "  Resource Group: $TemplateSpecRG"
Write-Host "  Version: $TemplateSpecVersion"
Write-Host "  ID: $templateSpecId"
Write-Host ""
Write-Host "Next Steps:"
Write-Host "  1. Deploy via Azure Portal:"
Write-Host "     Navigate to Template Specs → $TemplateSpecName → Deploy"
Write-Host ""
Write-Host "  2. Deploy via PowerShell:"
Write-Host "     New-AzSubscriptionDeployment ``"
Write-Host "       -Location $TemplateSpecLocation ``"
Write-Host "       -TemplateSpecId `"$templateSpecId`" ``"
Write-Host "       -TemplateParameterFile main.bicepparam"
Write-Host ""
Write-Host "  3. View in Portal:"
Write-Host "     https://portal.azure.com/#resource$templateSpecId"
Write-Host ""
Write-Host "================================================================================" -ForegroundColor Green
