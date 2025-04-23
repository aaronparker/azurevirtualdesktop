targetScope = 'resourceGroup'

@description('The region to deploy resources into')
param location string = resourceGroup().location

@description('Abbreviations for resource names')
param abbr object

@description('The id of the subnet to connect the private endpoint to')
param subnetId string

@description('The id of the storage account to connect the private endpoint to')
param storageAccountId string

@description('The name of the private endpoint')
param privateEndpointName string = uniqueString(resourceGroup().name)

@description('The name of the private link connection')
param privateLinkConnectionName string = uniqueString(resourceGroup().name)

@description('')
param privateDNSZoneId string

@description('A tags object used to assign tags to resources')
param tags object

// Create the private endpoint, connect to the target subnet, and enable for file services
resource privateEndpoint 'Microsoft.Network/privateEndpoints@2023-11-01' = {
  name: '${abbr.privateEndpoint}-${privateEndpointName}'
  location: location
  tags: tags
  properties: {
    subnet: {
      id: subnetId
    }
    privateLinkServiceConnections: [
      {
        name: '${abbr.privateLink}-${privateLinkConnectionName}'
        properties: {
          privateLinkServiceId: storageAccountId
          groupIds: [
            'file'
          ]
        }
      }
    ]
  }

  resource privateDNSZoneGroup 'privateDnsZoneGroups@2023-11-01' = {
    name: 'dnsgroupname'
    properties: {
      privateDnsZoneConfigs: [
        {
          name: 'config1'
          properties: {
            privateDnsZoneId: privateDNSZoneId
          }
        }
      ]
    }
  }
}
