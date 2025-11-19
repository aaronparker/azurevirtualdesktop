using 'main.bicep'

// ================================================================================
// Azure Key Vault Parameters File Example
// ================================================================================
// This example demonstrates how to reference secrets stored in Azure Key Vault.
// This is the RECOMMENDED approach for production deployments.
//
// Prerequisites:
// 1. Create an Azure Key Vault
// 2. Store the following secrets in the Key Vault:
//    - adminUsername
//    - adminPassword
//    - adDomainName (if using AD join)
//    - adDomainJoinUsername (if using AD join)
//    - adDomainJoinPassword (if using AD join)
//    - adOuPath (optional, if using AD join)
// 3. Grant the deployment identity access to read secrets from the Key Vault
// 4. Update the getSecret() calls below with your subscription, resource group, and Key Vault name

// ================================================================================
// VM Configuration
// ================================================================================
param vmName = 'TestVM01'
param location = 'australiaeast'
param availabilityZone = '1'
param vmSize = 'Standard_D4as_v5'
param osDiskType = 'Standard_LRS'

// ================================================================================
// Image Configuration
// ================================================================================
param imagePublisher = 'MicrosoftWindowsDesktop'
param imageOffer = 'office-365' // 'Windows-11'
param imageSku = 'win11-25h2-avd-m365' // 'win11-25h2-ent'
param imageVersion = 'latest'

// ================================================================================
// Static variables
// ================================================================================
var resouceGroupName = 'rg-Avd1Images-aue'
var keyVaultName = 'kv-Avd1-esplbxulhz-aue'
var subscriptionId = '4fc4c8ac-a2b8-4b39-9729-f1a5eeacbab5'

var virtualNetworkResourceGroup = 'rg-Avd1-Network-aue'
var virtualNetworkName = 'vnet-Avd1-HostPools-australiaeast'

// ================================================================================
// Administrator Credentials - FROM KEY VAULT
// ================================================================================
// Replace with your actual subscription ID, resource group, and Key Vault name
param adminUsername = getSecret(subscriptionId, resouceGroupName, keyVaultName, 'adminUsername')
param adminPassword = getSecret(subscriptionId, resouceGroupName, keyVaultName, 'adminPassword')

// ================================================================================
// Network Configuration
// ================================================================================
param vnetResourceId = '/subscriptions/${subscriptionId}/resourceGroups/${virtualNetworkResourceGroup}/providers/Microsoft.Network/virtualNetworks/${virtualNetworkName}'
param subnetName = 'Desktops4'

// ================================================================================
// Domain Join Configuration - FROM KEY VAULT
// ================================================================================
param domainJoinType = 'EntraID'

// Replace with your actual subscription ID, resource group, and Key Vault name
param adDomainName = getSecret(subscriptionId, resouceGroupName, keyVaultName, 'adDomainName')
param adDomainJoinUsername = getSecret(subscriptionId, resouceGroupName, keyVaultName, 'adDomainJoinUsername')
param adDomainJoinPassword = getSecret(subscriptionId, resouceGroupName, keyVaultName, 'adDomainJoinPassword')
param adOuPath = getSecret(subscriptionId, resouceGroupName, keyVaultName, 'adOuPath')

// ================================================================================
// Additional Settings
// ================================================================================
param enableTrustedLaunch = true  // Set to false for Standard (non-Trusted Launch) VMs
param enableBootDiagnostics = true

// ================================================================================
// Custom Script Execution
// ================================================================================
param runCustomScript = false
param scriptUrl = ''
param scriptFileName = ''
param scriptArguments = ''

// ================================================================================
// Tags
// ================================================================================
param tags = {
  Environment: 'QA'
  ManagedBy: 'QA Team'
  CostCenter: 'QA'
  Application: 'Nerdio Migrate'
}
