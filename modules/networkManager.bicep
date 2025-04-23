targetScope = 'resourceGroup'

@description('The region to deploy resources into')
param location string = resourceGroup().location

@description('The network manager name.')
param networkManagerName string

@description('The network group name.')
param networkGroupName string

@description('The service abbreviation we are deploying')
param service string

@description('Description for the network manager.')
param nmDescription string = 'Network management for ${applicationTag} networks.'

@description('Description for the network group.')
param ngDescription string = 'Groups networks for ${applicationTag}.'

@description('A list of subscriptions to add to the management scope')
param subscriptionId array = []

@description('The application tag to be used in the network manager and network group descriptions')
param applicationTag string

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

resource networkManager 'Microsoft.Network/networkManagers@2023-11-01' = {
  name: networkManagerName
  location: location
  tags: tagsUnion
  properties: {
    description: nmDescription
    networkManagerScopeAccesses: [
      'Connectivity'
    ]
    networkManagerScopes: {
      // managementGroups: [
      //   'string'
      // ]
      subscriptions: subscriptionId
    }
  }

  resource networkGroup 'networkGroups@2023-11-01' = {
    name: networkGroupName
    properties: {
      description: ngDescription
    }
  }

  resource connectivityConfigurations 'connectivityConfigurations@2023-11-01' = {
    name: '${service}-MeshNetwork'
    properties: {
      connectivityTopology: 'mesh'
      hubs: []
      appliesToGroups: [
        {
          networkGroupId: networkGroup.id
          groupConnectivity: 'directlyConnected'
          useHubGateway: 'false'
          isGlobal: 'true'
        }
      ]
      deleteExistingPeering: 'false'
      isGlobal: 'true'
    }
  }
}
