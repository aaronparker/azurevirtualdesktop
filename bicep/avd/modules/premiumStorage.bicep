targetScope = 'resourceGroup'

@description('The region to deploy resources into')
param location string = resourceGroup().location

@description('Abbreviations for resource names')
param abbr object

@description('Name of Storage Account - must be unique within Azure. Must be no longer than 15 characters to enable AD join')
@maxLength(15)
@minLength(4)
param storageAccountName string = 'storageaccount'

// If storageAccountName is the default value, generate a unique name name, otherwise use the passed value
var storageAccountNameToUse = (storageAccountName == 'storageaccount' ? substring('${abbr.storage}${uniqueString(resourceGroup().id, location)}', 0, 14) : storageAccountName)

@description('The performance tier of the storage account. Premium_ZRS is used by default to provide performance.')
@allowed([
  'Standard_LRS'
  'Standard_ZRS'
  'Premium_LRS'
  'Premium_ZRS'
])
param sku string = 'Premium_ZRS'

@description('An array of the file shares to add to the storage account')
param fileShares array

@description('Resource group that contains the virtual network')
param vnetResourceGroup string

@description('The virtual network name')
param virtualNetwork string

@description('The private DNS zone name')
param privateDNSZoneName string = 'privatelink.file.${environment().suffixes.storage}'

@description('An array that the subnets in the target virtual network will be added to')
param subnets array

@description('An array that the subnets in the target virtual network will be added to')
param storageSubnet string = 'Storage'

@description('Tags object to be combined with object specific tags')
param tags object

@description('Combine the tags parameters into object specific tag values')
param tagsUnion object = union (tags, {
  Application: resourceGroup().tags.Application
  LastUpdateDate: utcNow('yyyy-M-dd HH:mm:ss')
  Criticality: resourceGroup().tags.Criticality
  Function: 'User profiles'
  Type: resourceGroup().tags.Type
})

// Get details of subnets on the specified existing network
resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' existing = {
  name: virtualNetwork
  scope: resourceGroup(vnetResourceGroup)
}
resource vnetSubnets 'Microsoft.Network/virtualNetworks/subnets@2024-05-01' existing = [for subnet in subnets: {
  name : subnet
  parent: vnet
}]
resource pipSubnet 'Microsoft.Network/virtualNetworks/subnets@2024-05-01' existing = {
  name : storageSubnet
  parent: vnet
}
resource privateDNSZone 'Microsoft.Network/privateDnsZones@2024-06-01' existing = {
  name: privateDNSZoneName
  scope: resourceGroup(vnetResourceGroup)
}

// Create the storage account and file shares. Storage account name is trimmed to 15 characters
resource storageAccount 'Microsoft.Storage/storageAccounts@2024-01-01' = {
  name: storageAccountNameToUse
  location: location
  tags: tagsUnion
  sku: {
    name: sku
  }
  kind: (startsWith(sku, 'Premium') ? 'FileStorage' : 'StorageV2')
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
    allowBlobPublicAccess: false
    allowSharedKeyAccess: true
    largeFileSharesState: 'Enabled'
    networkAcls: {
      bypass: 'AzureServices'
      virtualNetworkRules: [for (subnet,index) in subnets: {
          id: vnetSubnets[index].id
          action: 'Allow'
       }]
      ipRules: []
      defaultAction: 'Deny'
    }
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

  // Configure file services
  resource fileServices 'fileServices@2024-01-01' = {
    name: 'default'
    properties: {
      protocolSettings: startsWith(sku, 'Premium') ? {
        smb: {
          multichannel: {
            enabled: true
          }
        }
      } : null
      cors: {
        corsRules: []
      }
      shareDeleteRetentionPolicy: startsWith(sku, 'Premium') ? {
        allowPermanentDelete: true
        enabled: true
        days: 7
      } : null
    }

    // Create each of the specified file shares
    resource shares 'shares@2024-01-01' = [for name in fileShares: {
      name: name
      properties: {
        accessTier: (startsWith(sku, 'Premium') ? 'Premium' : 'TransactionOptimized')
        shareQuota: 100
        enabledProtocols: 'SMB'
      }
    }]
  }
}

// Create the private endpoint and connect to the storage account
module privateEndpoints 'privateEndpoints.bicep' = {
  name: 'privateEndpoints${storageAccountNameToUse}'
  params: {
    location: location
    abbr: abbr
    tags: tagsUnion
    storageAccountId: storageAccount.id
    subnetId: pipSubnet.id
    privateEndpointName: storageAccountNameToUse
    privateDNSZoneId: privateDNSZone.id
  }
}
