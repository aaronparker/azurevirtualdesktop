// ================================================================================
// Azure Template Spec - Simplified Windows VM Deployment
// ================================================================================
// Simplified interface for deploying Windows VMs with Key Vault integration
// Provides only essential configuration options
//
// Note: Credentials are retrieved from Azure Key Vault secrets

metadata name = 'Windows VM Template Spec'
metadata description = 'Simplified Windows VM deployment with Key Vault secret integration'
metadata version = '1.0.0'

targetScope = 'subscription'

// ================================================================================
// Required Parameters
// ================================================================================

@description('Name of the virtual machine')
param vmName string

@description('Name of the resource group for the VM (will be created if it does not exist)')
param resourceGroupName string

@description('Azure region for deployment')
param location string

@description('Resource ID of the existing virtual network')
param vnetResourceId string

@description('Name of the subnet in the virtual network')
param subnetName string

@description('Resource ID of the Azure Key Vault containing credentials (Format: /subscriptions/{sub-id}/resourceGroups/{rg-name}/providers/Microsoft.KeyVault/vaults/{vault-name})')
param keyVaultResourceId string

@description('Domain join type')
@allowed([
  'None'
  'ActiveDirectory'
  'EntraID'
])
param domainJoinType string

// ================================================================================
// Credential Parameters (from Key Vault)
// ================================================================================

@description('Administrator username (retrieved from Key Vault)')
@secure()
param adminUsername string

@description('Administrator password (retrieved from Key Vault)')
@secure()
param adminPassword string

@description('Active Directory domain name (retrieved from Key Vault, required for AD join)')
param adDomainName string = ''

@description('Active Directory domain join username (retrieved from Key Vault, required for AD join)')
param adDomainJoinUsername string = ''

@description('Active Directory domain join password (retrieved from Key Vault, required for AD join)')
@secure()
param adDomainJoinPassword string = ''

@description('Active Directory OU path (retrieved from Key Vault, optional)')
param adOuPath string = ''

// ================================================================================
// Optional Parameters with Defaults
// ================================================================================

@description('Virtual machine size')
param vmSize string = 'Standard_D4s_v5'

@description('OS Disk storage type')
@allowed([
  'Standard_LRS'
  'StandardSSD_LRS'
  'Premium_LRS'
  'StandardSSD_ZRS'
  'Premium_ZRS'
])
param osDiskType string = 'Premium_LRS'

@description('Availability zone (1, 2, 3, or empty for no zone)')
@allowed([
  ''
  '1'
  '2'
  '3'
])
param availabilityZone string = '1'

@description('Windows image type')
@allowed([
  'Windows Server 2022 Datacenter'
  'Windows Server 2019 Datacenter'
  'Windows 11 Enterprise'
  'Windows 10 Enterprise'
])
param windowsImageType string = 'Windows 11 Enterprise'

@description('Enable Trusted Launch security')
param enableTrustedLaunch bool = true

@description('Tags to apply to resources')
param tags object = {
  ManagedBy: 'TemplateSpec'
  DeploymentDate: utcNow('yyyy-MM-dd')
}

// ================================================================================
// Variables
// ================================================================================

// Image configuration based on selection
var imageConfigurations = {
  'Windows Server 2022 Datacenter': {
    publisher: 'MicrosoftWindowsServer'
    offer: 'WindowsServer'
    sku: '2022-datacenter-azure-edition'
    version: 'latest'
  }
  'Windows Server 2019 Datacenter': {
    publisher: 'MicrosoftWindowsServer'
    offer: 'WindowsServer'
    sku: '2019-datacenter-gensecond'
    version: 'latest'
  }
  'Windows 11 Enterprise': {
    publisher: 'MicrosoftWindowsDesktop'
    offer: 'Windows-11'
    sku: 'win11-23h2-ent'
    version: 'latest'
  }
  'Windows 10 Enterprise': {
    publisher: 'MicrosoftWindowsDesktop'
    offer: 'Windows-10'
    sku: 'win10-22h2-ent'
    version: 'latest'
  }
}

var selectedImage = imageConfigurations[windowsImageType]

// ================================================================================
// Resources
// ================================================================================

// Resource Group (create if it doesn't exist)
resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: resourceGroupName
  location: location
  tags: tags
}

// VM Deployment Module
module vmDeployment '../main.bicep' = {
  name: '${vmName}-deployment'
  scope: rg
  params: {
    vmName: vmName
    location: location
    availabilityZone: availabilityZone
    vmSize: vmSize
    osDiskType: osDiskType
    imagePublisher: selectedImage.publisher
    imageOffer: selectedImage.offer
    imageSku: selectedImage.sku
    imageVersion: selectedImage.version
    adminUsername: adminUsername
    adminPassword: adminPassword
    vnetResourceId: vnetResourceId
    subnetName: subnetName
    domainJoinType: domainJoinType
    adDomainName: adDomainName
    adDomainJoinUsername: adDomainJoinUsername
    adDomainJoinPassword: adDomainJoinPassword
    adOuPath: adOuPath
    enableTrustedLaunch: enableTrustedLaunch
    enableBootDiagnostics: true
    runCustomScript: false
    scriptUrl: ''
    scriptFileName: ''
    scriptArguments: ''
    tags: tags
  }
}

// ================================================================================
// Outputs
// ================================================================================

@description('Resource ID of the deployed virtual machine')
output vmResourceId string = vmDeployment.outputs.vmResourceId

@description('Name of the virtual machine')
output vmName string = vmDeployment.outputs.vmName

@description('Private IP address of the VM')
output privateIpAddress string = vmDeployment.outputs.privateIpAddress

@description('Availability zone')
output zone string = vmDeployment.outputs.zone

@description('Domain join type')
output domainJoinType string = vmDeployment.outputs.domainJoinType

@description('License type')
output licenseType string = vmDeployment.outputs.licenseType

@description('Trusted Launch enabled')
output trustedLaunchEnabled bool = vmDeployment.outputs.trustedLaunchEnabled

@description('Resource group name')
output resourceGroupName string = resourceGroupName
