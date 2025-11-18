using 'main.bicep'

// ================================================================================
// Template Spec Parameters File
// ================================================================================
// This parameters file is used with the Windows VM Template Spec.
// Credentials are retrieved from Azure Key Vault.
//
// Usage:
// 1. Update the Key Vault resource ID below
// 2. Ensure secrets exist in Key Vault with the specified names
// 3. Deploy using: az deployment sub create --location <location> --template-file main.bicep --parameters main.bicepparam

// ================================================================================
// Required Parameters
// ================================================================================

param vmName = 'myWindowsVM01'
param resourceGroupName = 'rg-windows-vms'
param location = 'eastus'

// Network Configuration
param vnetResourceId = '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-network/providers/Microsoft.Network/virtualNetworks/vnet-main'
param subnetName = 'subnet-vms'

// Key Vault Configuration
param keyVaultResourceId = '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/rg-keyvault/providers/Microsoft.KeyVault/vaults/kv-credentials'

// Domain Join Configuration
param domainJoinType = 'ActiveDirectory'  // Options: 'None', 'ActiveDirectory', 'EntraID'

// ================================================================================
// Credentials from Key Vault
// ================================================================================
// Replace subscription ID, resource group, and Key Vault name with your actual values

// Admin Credentials (required)
param adminUsername = getSecret('00000000-0000-0000-0000-000000000000', 'rg-keyvault', 'kv-credentials', 'adminUsername')
param adminPassword = getSecret('00000000-0000-0000-0000-000000000000', 'rg-keyvault', 'kv-credentials', 'adminPassword')

// Active Directory Credentials (required only if domainJoinType = 'ActiveDirectory')
param adDomainName = getSecret('00000000-0000-0000-0000-000000000000', 'rg-keyvault', 'kv-credentials', 'adDomainName')
param adDomainJoinUsername = getSecret('00000000-0000-0000-0000-000000000000', 'rg-keyvault', 'kv-credentials', 'adDomainJoinUsername')
param adDomainJoinPassword = getSecret('00000000-0000-0000-0000-000000000000', 'rg-keyvault', 'kv-credentials', 'adDomainJoinPassword')
param adOuPath = getSecret('00000000-0000-0000-0000-000000000000', 'rg-keyvault', 'kv-credentials', 'adOuPath')

// ================================================================================
// Optional Parameters
// ================================================================================

param vmSize = 'Standard_D4s_v5'
param osDiskType = 'Premium_LRS'
param availabilityZone = '1'
param windowsImageType = 'Windows 11 Enterprise'  // Options: 'Windows Server 2022 Datacenter', 'Windows Server 2019 Datacenter', 'Windows 11 Enterprise', 'Windows 10 Enterprise'
param enableTrustedLaunch = true

param tags = {
  Environment: 'Production'
  ManagedBy: 'TemplateSpec'
  Application: 'WindowsVM'
}
