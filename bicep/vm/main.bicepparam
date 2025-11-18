using 'main.bicep'

// ================================================================================
// VM Configuration
// ================================================================================
param vmName = 'myWindowsVM'
param location = 'eastus'
param availabilityZone = '1'  // Use '1', '2', '3', or '' for no zone
param vmSize = 'Standard_D4s_v5'  // Zone-redundant capable size
param osDiskType = 'Premium_LRS'

// ================================================================================
// Image Configuration
// ================================================================================
// Windows Server 2022 (Datacenter with Azure Edition)
// param imagePublisher = 'MicrosoftWindowsServer'
// param imageOffer = 'WindowsServer'
// param imageSku = '2022-datacenter-azure-edition-core'
// param imageVersion = 'latest'

// For Windows 11 Enterprise, use these instead:
param imagePublisher = 'MicrosoftWindowsDesktop'
param imageOffer = 'Windows-11'
param imageSku = 'win11-25h2-ent'
param imageVersion = 'latest'

// For Windows 10 Enterprise, use these instead:
// param imagePublisher = 'MicrosoftWindowsDesktop'
// param imageOffer = 'Windows-10'
// param imageSku = 'win10-22h2-ent'
// param imageVersion = 'latest'

// ================================================================================
// Administrator Credentials - Using Azure Key Vault
// ================================================================================
// To use secrets from Azure Key Vault, reference them using the getSecret() function.
// Replace the values below with your Key Vault resource ID and secret names.

// OPTION 1: Reference secrets from Key Vault (RECOMMENDED)
// Uncomment and configure these lines to use Key Vault:
// param adminUsername = getSecret('<subscription-id>', '<keyvault-rg>', '<keyvault-name>', 'adminUsername')
// param adminPassword = getSecret('<subscription-id>', '<keyvault-rg>', '<keyvault-name>', 'adminPassword')

// OPTION 2: Provide values directly (NOT RECOMMENDED for production)
param adminUsername = 'azureadmin'
param adminPassword = ''  // Must be provided at deployment time

// ================================================================================
// Network Configuration
// ================================================================================
// Replace with your existing virtual network resource ID
param vnetResourceId = '/subscriptions/<subscription-id>/resourceGroups/<vnet-rg>/providers/Microsoft.Network/virtualNetworks/<vnet-name>'
param subnetName = 'default'

// ================================================================================
// Domain Join Configuration - Using Azure Key Vault
// ================================================================================
// Options: 'None', 'ActiveDirectory', 'EntraID'
param domainJoinType = 'None'

// Active Directory Domain Join (only required if domainJoinType = 'ActiveDirectory')
// 
// OPTION 1: Reference secrets from Key Vault (RECOMMENDED)
// Uncomment and configure these lines to use Key Vault:
// param adDomainName = getSecret('<subscription-id>', '<keyvault-rg>', '<keyvault-name>', 'adDomainName')
// param adDomainJoinUsername = getSecret('<subscription-id>', '<keyvault-rg>', '<keyvault-name>', 'adDomainJoinUsername')
// param adDomainJoinPassword = getSecret('<subscription-id>', '<keyvault-rg>', '<keyvault-name>', 'adDomainJoinPassword')
// param adOuPath = getSecret('<subscription-id>', '<keyvault-rg>', '<keyvault-name>', 'adOuPath')

// OPTION 2: Provide values directly (NOT RECOMMENDED for production)
param adDomainName = 'contoso.com'
param adDomainJoinUsername = 'domain\\joiner'
param adDomainJoinPassword = ''  // Must be provided at deployment time if using AD join
param adOuPath = ''  // Optional: e.g., 'OU=Servers,DC=contoso,DC=com'

// ================================================================================
// Additional Settings
// ================================================================================
param enableTrustedLaunch = true  // Set to false for Standard (non-Trusted Launch) VMs
param enableBootDiagnostics = true

// ================================================================================
// Custom Script Execution (Post-Deployment)
// ================================================================================
// Enable this to run a PowerShell script after deployment and domain join
param runCustomScript = false
param scriptUrl = 'https://raw.githubusercontent.com/yourorg/scripts/main/configure-vm.ps1'
param scriptFileName = 'configure-vm.ps1'
param scriptArguments = ''  // e.g., '-Parameter1 Value1 -Parameter2 Value2'

// Example configurations:
// 1. Simple script with no arguments:
//    param runCustomScript = true
//    param scriptUrl = 'https://mystorageaccount.blob.core.windows.net/scripts/setup.ps1'
//    param scriptFileName = 'setup.ps1'
//    param scriptArguments = ''
//
// 2. Script with arguments:
//    param runCustomScript = true
//    param scriptUrl = 'https://mystorageaccount.blob.core.windows.net/scripts/configure.ps1'
//    param scriptFileName = 'configure.ps1'
//    param scriptArguments = '-Environment Production -Region EastUS'

param tags = {
  Environment: 'Production'
  ManagedBy: 'Infrastructure Team'
  CostCenter: 'IT-Operations'
}
