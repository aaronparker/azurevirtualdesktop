
@description('The region to deploy resources into')
param location string

@description('The Azure region short name to deploy the resources')
@maxLength(4)
param regionShortName string

// @description('Properties of the region')
// param regionProperties object

@description('An array of host pools')
param hostPools array

@description('Resource group for the virtual network to attached the storage account to')
param vnetResourceGroup string

@description('Virtual network to attach the storage account to')
param virtualNetwork string

@description('An array that the subnets in the target virtual network will be added to')
param subnets array

// Select just the name property from the subnets
var subnetNames = [for subnet in subnets: subnet.name]

@description('Subnet to attach the storage account to')
param storageSubnet string

@description('Abbreviations for resource names')
param abbr object

@description('Tags object to be combined with object specific tags')
param tags object

module hostPoolProfileStorage 'premiumStorage.bicep' = [for hostPool in hostPools: if(hostPool.deployStorage) {
  name: 'hostPoolProfileStorage-${hostPool.name}'
  scope: resourceGroup('${abbr.resourceGroup}-${abbr.service}-${hostPool.name}-${regionShortName}')
  params: {
    storageAccountName: (empty(hostPool.storageAccountLiteralName) ? null : hostPool.storageAccountLiteralName)
    location: location
    abbr: abbr
    tags: tags
    sku: hostPool.premiumStorageSku
    storageSubnet: storageSubnet
    vnetResourceGroup: vnetResourceGroup
    virtualNetwork: virtualNetwork
    subnets: subnetNames
    fileShares: hostPool.fileShares
  }
}]
