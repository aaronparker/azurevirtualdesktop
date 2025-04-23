targetScope = 'resourceGroup'

@description('The location of the resources')
param location string = resourceGroup().location

@description('The Azure region short name to deploy the resources')
@maxLength(4)
param regionShortName string

@description('Abbreviations for resource names')
param abbr object

@description('Name of Storage Account. Must be unique within Azure')
@maxLength(24)
param keyVaultName string = '${abbr.keyVault}-${abbr.Service}-${substring(uniqueString(resourceGroup().id, location), 0, 10)}-${regionShortName}'

@description('Tags object to be combined with object specific tags')
param tags object

@description('Combine the tags parameters into object specific tag values')
param tagsUnion object = union (tags, {
  Application: resourceGroup().tags.Application
  LastUpdateDate: utcNow('yyyy-M-dd')
  Criticality: resourceGroup().tags.Criticality
  Function: resourceGroup().tags.Function
  Type: resourceGroup().tags.Type
})

// @description('The name of the key to be created.')
// param keyName string

@description('The SKU of the vault to be created.')
@allowed([
  'standard'
  'premium'
])
param skuName string = 'standard'

// @description('The JsonWebKeyType of the key to be created.')
// @allowed([
//   'EC'
//   'EC-HSM'
//   'RSA'
//   'RSA-HSM'
// ])
// param keyType string = 'RSA'

// @description('The permitted JSON web key operations of the key to be created.')
// param keyOps array = []

// @description('The size in bits of the key to be created.')
// param keySize int = 2048

// @description('The JsonWebKeyCurveName of the key to be created.')
// @allowed([
//   ''
//   'P-256'
//   'P-256K'
//   'P-384'
//   'P-521'
// ])
// param curveName string = ''

resource vault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: keyVaultName
  location: location
  tags: tagsUnion
  properties: {
    accessPolicies:[]
    enableRbacAuthorization: false
    enableSoftDelete: true
    softDeleteRetentionInDays: 90
    enabledForDeployment: true
    enabledForDiskEncryption: true
    enabledForTemplateDeployment: true
    tenantId: subscription().tenantId
    sku: {
      name: skuName
      family: 'A'
    }
    networkAcls: {
      defaultAction: 'Allow'
      bypass: 'AzureServices'
    }
  }
}

// resource key 'Microsoft.KeyVault/vaults/keys@2023-07-01' = {
//   parent: vault
//   name: keyName
//   properties: {
//     kty: keyType
//     keyOps: keyOps
//     keySize: keySize
//     curveName: curveName
//   }
// }

//output proxyKey object = key.properties
