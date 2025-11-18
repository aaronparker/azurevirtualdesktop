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
param vmName = 'myWindowsVM'
param location = 'eastus'
param availabilityZone = '1'
param vmSize = 'Standard_D4s_v5'
param osDiskType = 'Premium_LRS'

// ================================================================================
// Image Configuration
// ================================================================================
param imagePublisher = 'MicrosoftWindowsDesktop'
param imageOffer = 'Windows-11'
param imageSku = 'win11-25h2-ent'
param imageVersion = 'latest'

// ================================================================================
// Administrator Credentials - FROM KEY VAULT
// ================================================================================
// Replace with your actual subscription ID, resource group, and Key Vault name
param adminUsername = getSecret('00000000-0000-0000-0000-000000000000', 'myKeyVaultRG', 'myKeyVault', 'adminUsername')
param adminPassword = getSecret('00000000-0000-0000-0000-000000000000', 'myKeyVaultRG', 'myKeyVault', 'adminPassword')

// ================================================================================
// Network Configuration
// ================================================================================
param vnetResourceId = '/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/myNetworkRG/providers/Microsoft.Network/virtualNetworks/myVNet'
param subnetName = 'default'

// ================================================================================
// Domain Join Configuration - FROM KEY VAULT
// ================================================================================
param domainJoinType = 'ActiveDirectory'

// Replace with your actual subscription ID, resource group, and Key Vault name
param adDomainName = getSecret('00000000-0000-0000-0000-000000000000', 'myKeyVaultRG', 'myKeyVault', 'adDomainName')
param adDomainJoinUsername = getSecret('00000000-0000-0000-0000-000000000000', 'myKeyVaultRG', 'myKeyVault', 'adDomainJoinUsername')
param adDomainJoinPassword = getSecret('00000000-0000-0000-0000-000000000000', 'myKeyVaultRG', 'myKeyVault', 'adDomainJoinPassword')
param adOuPath = getSecret('00000000-0000-0000-0000-000000000000', 'myKeyVaultRG', 'myKeyVault', 'adOuPath')

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
  Environment: 'Production'
  ManagedBy: 'Infrastructure Team'
  CostCenter: 'IT-Operations'
}
