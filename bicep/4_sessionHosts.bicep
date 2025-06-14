targetScope = 'resourceGroup'

// Parameters to edit
param managementResourceGroup string = 'rg-Avd1-Management-aue'
param keyVault string = 'kv-Avd1-4f5fzzby72-aue'

param virtualNetworkResourceGroup string = 'rg-Avd1-Network-aue'
param virtualNetworkName string = 'vnet-Avd1-HostPools-australiaeast'
param subnetName string = 'Desktops1'

// param hostPoolResourceGroup string = 'rg-Avd-HostPool01-australiaeast'  <- target the resource group via the 'az deployment group' command
param hostPoolName string = 'vdpool-Avd1-HostPool01-Personal-aue'
param vmNamePrefix string = 'avd-aue-'
param numberOfSessionHosts int = 1
param sessionHostStartNumber int = 1
param vmSize string = 'Standard_D4as_v5'

param vmImageResourceGroup string = 'rg-Avd1Images-aue'
param vmImageGalleryName string = 'galAvd1Imagesaustraliaeast'
param vmImageTemplate string = 'MicrosoftWindowsDesktop-Windows-11-win11-24h2-ent-en-au'
param vmImageVersion string = 'latest'
// param managedIdentity string = 'idAvdImagesaustraliaeast'

@description('The availability option for the VMs')
@allowed([
  'None'
  'AvailabilitySet'
  'AvailabilityZone'
])
param availabilityOption string = 'AvailabilityZone'
param availabilitySetName string = 'avail-AvdHostPool01-aue'

param joinEntraID bool = true // Set to false to join AD
param enrolIntune bool = true

param customConfigurationScriptUrl string = 'https://stavddsplbxulhzmac.blob.${environment().suffixes.storage}/scripts/PersonalDesktopHostDeployment.ps1'

// Don't touch these parameters
param LastUpdateDate string = utcNow('yyyy-M-dd HH:mm:ss HH:mm:ss')

@description('The UPN of the user deploying the environment - must pass via the CLI')
param upn string

@description('Additional tag values')
var tags = json(loadTextContent('./params/tags.json'))


// Get the Key Vault that contains secret values for session host deployment
resource kv 'Microsoft.KeyVault/vaults@2024-11-01' existing = {
  name: keyVault
  scope: resourceGroup(subscription().subscriptionId, managementResourceGroup)
}

// Get the id of the target subnet
resource virtualNetwork 'Microsoft.Network/virtualNetworks@2024-05-01' existing = {
  name: virtualNetworkName
  scope: resourceGroup(virtualNetworkResourceGroup)
}
resource subnet 'Microsoft.Network/virtualNetworks/subnets@2024-05-01' existing = {
  name: subnetName
  parent: virtualNetwork
}

// Get the id of the target host pool
resource hostPool 'Microsoft.DesktopVirtualization/hostPools@2024-04-03' existing = {
  name: hostPoolName
  scope: resourceGroup(managementResourceGroup)
}

// Get the id of the target image
resource vmGallery 'Microsoft.Compute/galleries@2024-03-03' existing = {
  name: vmImageGalleryName
  scope: resourceGroup(vmImageResourceGroup)
}
resource existingVmImageTemplate 'Microsoft.Compute/galleries/images@2024-03-03' existing = {
  name: vmImageTemplate
  parent: vmGallery
}
resource existingVmImage 'Microsoft.Compute/galleries/images/versions@2024-03-03' existing = {
  name: vmImageVersion
  parent: existingVmImageTemplate
}

module sessionHosts 'modules/sessionHostsDeployment.bicep' = {
  name: 'sessionHostsDeployment'
  params: {
    tags: union (tags, {
      'cm-resource-parent': hostPool.id
      Application: resourceGroup().tags.Application
      LastUpdateBy: upn
      LastUpdateDate: LastUpdateDate
      Criticality: resourceGroup().tags.Criticality
      Function: resourceGroup().tags.Function
      Type: resourceGroup().tags.Type
    })
    administratorAccountUsername: kv.getSecret('administratorAccountUsername')
    administratorAccountPassword: kv.getSecret('administratorAccountPassword')
    ouPath: kv.getSecret('ouPath')
    domain: kv.getSecret('domain')
    vmAdministratorAccountUsername: kv.getSecret('vmAdministratorAccountUsername')
    vmAdministratorAccountPassword: kv.getSecret('vmAdministratorAccountPassword')
    storageAccountName: kv.getSecret('storageAccountName-${hostPoolName}')
    storageAccountKey: kv.getSecret('storageAccountKey-${hostPoolName}')
    hostPoolToken: kv.getSecret('hostPoolToken-${hostPoolName}')
    entraJoin: joinEntraID
    intune: enrolIntune
    hostPoolName: hostPoolName
    subnetId: subnet.id
    rdshPrefix: vmNamePrefix
    rdshNumberOfInstances: numberOfSessionHosts
    vmInitialNumber: sessionHostStartNumber
    rdshImageSourceId: existingVmImage.id
    rdshVmSize: vmSize
    //userAssignedIdentity: managedIdentity
    customConfigurationScriptUrl: customConfigurationScriptUrl
    availabilityOption: availabilityOption
    availabilitySetName: availabilitySetName
  }
}
