targetScope = 'resourceGroup'

@description('The region to deploy resources into')
param location string = resourceGroup().location

@description('Abbreviations for resource names')
param abbr object

@description('Name of Storage Account. Must be unique within Azure')
@maxLength(13)
@minLength(4)
param storageAccountName string = uniqueString(resourceGroup().id, location)

@description('The performance tier of the storage account. Standard_ZRS or Standard_ZRS is used by default to provide lower cost')
@allowed([
  'Standard_LRS'
  'Standard_ZRS'
])
param sku string = 'Standard_ZRS'

@description('An array of the container names to add to the storage account')
param containerNames array = [
  'binaries'
  'configs'
]

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

// Create a standard tier storage account with blob containers for use with custom images
resource storageAccount 'Microsoft.Storage/storageAccounts@2024-01-01' = {
  name: '${abbr.storage}${storageAccountName}'
  location: location
  tags: tagsUnion
  sku: {
    name: sku
  }
  kind: 'StorageV2'
  properties: {
    dnsEndpointType: 'Standard'
    allowedCopyScope: 'AAD'
    defaultToOAuthAuthentication: false
    publicNetworkAccess: 'Enabled'
    keyPolicy: {
      keyExpirationPeriodInDays: 60
    }
    allowCrossTenantReplication: false
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: true
    allowSharedKeyAccess: true
    supportsHttpsTrafficOnly: true
    encryption: {
      requireInfrastructureEncryption: false
      services: {
        file: {
          keyType: 'Account'
          enabled: true
        }
        blob: {
          keyType: 'Account'
          enabled: true
        }
      }
      keySource: 'Microsoft.Storage'
    }
  }

  resource blobServices 'blobServices@2024-01-01' = {
    name: 'default'
    properties: {
      cors: {
        corsRules: []
      }
    }

    resource containers 'containers@2024-01-01' = [for name in containerNames: {
      name: name
      properties: {
        publicAccess: 'Blob'
      }
    }]
  }
}
