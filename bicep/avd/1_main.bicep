// Resource groups need to target the subscription
targetScope = 'subscription'

@description('Abbreviations for resource names')
var abbr = json(loadTextContent('./params/abbreviations.json'))

// @description('Azure Virtual Desktop role definitions')
// var roleDefinitions = json(loadTextContent('./params/roles.json'))

@description('An array of Azure regions to deploy resources into')
var regions = json(loadTextContent('./params/regions.json'))

@description('The management resource group name')
param managementResourceGroup string = 'Management'

@description('Security rules to be applied to network security groups')
var nsgRules = json(loadTextContent('./params/nsgRules.json'))

@description('The RDP properties for the host pool')
var rdpProperties = json(loadTextContent('./params/rdpSettings.json'))

// @description('Scaling plan schedule settings')
// var scalingPlanSchedules = json(loadTextContent('./params/scalingPlanSchedules.json'))

@description('The UPN of the user deploying the environment - must pass via the CLI')
param upn string

@description('Additional tag values')
var tagsFile = json(loadTextContent('./params/tags.json'))

@description('Union of tags with the user\'s upn')
var tags = union(tagsFile, {
  LastUpdateBy: upn
})

// Filter for regions that are enabled for deployment. Ensure `"deployRegion": true` in the regions.json file
var regionsToDeploy = filter(regions, region => region.deployRegion == true)

// Loop through the resource module for each region to create core resource groups
module coreResourceGroups 'modules/resourceGroups.bicep' = [for region in regionsToDeploy: {
  name: 'coreResourceGroups-${region.location}'
  params: {
    location: region.location
    regionShortName: region.properties.shortName
    abbr: abbr
    tags: tags
    resourceGroups: region.coreResourceGroups
  }
}]

// Create a virtual network for each region. Ensure "deployNetwork": true in the regions.json file
module regionVirtualNetworks 'modules/virtualNetwork.bicep' = [for region in regionsToDeploy: if(region.network.deployNetwork) {
  name: 'virtualNetwork-${region.location}'
  scope: resourceGroup('${abbr.resourceGroup}-${abbr.service}-${region.network.resourceGroup}-${region.properties.shortName}')
  dependsOn: [
    coreResourceGroups
  ]
  params: {
    deployNatGateway: region.network.deployNatGateway
    location: region.location
    tags: tags
    vnetName: ((!empty(region.network.networkLiteralName)) ? region.network.networkLiteralName : '${abbr.network}-${abbr.service}-${region.network.name}-${region.location}')
    addressSpace: region.network.addressSpace
    subnets: region.network.subnets
    dnsServers: region.network.dnsServers
    nsgRules: nsgRules
    endpointsLocation: [
      region.location
      region.properties.pairedRegion
    ]
    hostPoolNsg: '${abbr.nsg}-${abbr.service}-${region.network.name}-${region.location}'
    publicIpName: '${abbr.publicIp}-${abbr.service}-${region.network.name}-${region.location}-01'
    natGatewayName: '${abbr.natGateway}-${abbr.service}-${region.network.name}-${region.location}-01'
    routeTableName: '${abbr.routeTable}-${abbr.service}-${region.network.name}-${region.location}-01'
  }
}]

// Create an Azure compute gallery for each region. Ensure "deployImages": true in the regions.json file
module computeGallery 'modules/computeGallery.bicep' = [for region in regionsToDeploy: if(region.customImages.deployImages) {
  name: 'computeGallery-${region.location}'
  scope: resourceGroup((!empty(region.customImages.resourceGroupLiteralName)) ? region.customImages.resourceGroupLiteralName : '${abbr.resourceGroup}-${abbr.service}-${region.customImages.resourceGroup}-${region.properties.shortName}')
  dependsOn: [
    coreResourceGroups
  ]
  params: {
    location: region.location
    tags: tags
    abbr: abbr
    images: region.customImages.images
    imageLanguage: region.properties.language
  }
}]

// Create a standard tier storage account for image management for each region
module imageStorage 'modules/standardStorage.bicep' = [for region in regionsToDeploy: if(region.customImages.deployImages) {
  name: 'imageStorage-${region.location}'
  scope: resourceGroup('${abbr.resourceGroup}-${abbr.service}-${region.customImages.resourceGroup}-${region.properties.shortName}')
  dependsOn: [
    coreResourceGroups
  ]
  params: {
    location: region.location
    tags: tags
    abbr: abbr
    containerNames: region.customImages.imageContainers
    sku: region.customImages.imageStorageSku
  }
}]

// Resource groups for host pools in each region
module hostPoolsResourceGroups 'modules/resourceGroups.bicep' = [for region in regionsToDeploy: {
  name: 'hostPoolResourceGroups-${region.location}'
  params: {
    location: region.location
    regionShortName: region.properties.shortName
    abbr: abbr
    tags: tags
    resourceGroups: region.hostPools
  }
}]

// Deploy storage accounts for host pools in each region for FSLogix containers
// For production deployments, these should be Premium_ZRS or Premium_LRS. Use Standard_LRS for testing
module hostPoolProfileStorage 'modules/loopHostPoolStorage.bicep' =  [for region in regionsToDeploy: {
  name: 'hostPoolProfileStorage-${region.location}'
  scope: resourceGroup('${abbr.resourceGroup}-${abbr.service}-${managementResourceGroup}-${region.properties.shortName}')
  dependsOn: [
    hostPoolsResourceGroups
    regionVirtualNetworks
  ]
  params: {
    location: region.location
    regionShortName: region.properties.shortName
    abbr: abbr
    tags: tags
    //regionProperties: region.properties
    hostPools: region.hostPools
    vnetResourceGroup: '${abbr.resourceGroup}-${abbr.service}-${region.network.resourceGroup}-${region.properties.shortName}'
    virtualNetwork: '${abbr.network}-${abbr.service}-${region.network.name}-${region.location}'
    subnets: region.network.subnets
    storageSubnet: region.network.storageSubnetName
  }
}]

// Create the host pool and application group objects for each region
// If using Nerdio Manager, these host pools can then be converted into dynamic host pools
module avdHostPools 'modules/loopAvdHostPool.bicep' = [for region in regionsToDeploy: {
  name: 'hostPools-${region.location}'
  scope: resourceGroup('${abbr.resourceGroup}-${abbr.service}-${managementResourceGroup}-${region.properties.shortName}')
  dependsOn: [
    coreResourceGroups
  ]
  params: {
    location: region.location
    abbr: abbr
    tags: tags
    hostPools: region.hostPools
    customRdpProperty: rdpProperties.Default
    metaDataLocation: ((empty(region.properties.metaDataRegion)) ? region.location : region.properties.metaDataRegion)
    regionShortName: region.properties.shortName
    timeZone: region.properties.timeZone
    // scalingPlanSchedules: scalingPlanSchedules
  }
}]

// Create a AVD workspace for each region
module avdWorkspaces 'modules/avdWorkspace.bicep' = [for region in regionsToDeploy: if(region.workspace.deployWorkspace) {
  name: 'workspace-${region.location}'
  scope: resourceGroup('${abbr.resourceGroup}-${abbr.service}-${region.workspace.resourceGroup}-${region.properties.shortName}')
  dependsOn: [
    coreResourceGroups
  ]
  params: {
    tags: tags
    location: region.location
    metaDataLocation: (empty(region.properties.metaDataRegion) ? region.location : region.properties.metaDataRegion)
    workspaceName: '${abbr.workspace}-${abbr.service}-${region.location}'
    workspaceFriendlyName: region.workspace.friendlyName
  }
}]

// Create Azure Log Analytics Workspace. Ensure "deployLogAnalytics": true in the regions.json file
// This can be skipped if using Nerdio Manager
module logAnalytics 'modules/logAnalytics.bicep' = [for region in regionsToDeploy: if(region.properties.deployLogAnalytics) {
  name: 'logAnalytics-${region.location}'
  scope: resourceGroup('${abbr.resourceGroup}-${abbr.service}-${managementResourceGroup}-${region.properties.shortName}')
  dependsOn: [
    coreResourceGroups
  ]
  params: {
    tags: tags
    workspaceName: '${abbr.logAnalytics}-${abbr.service}-${region.location}'
  }
}]

// Create a key vault for each region. Ensure "deployKeyVault": true in the regions.json file
module keyVault 'modules/keyVault.bicep' = [for region in regionsToDeploy: if(region.properties.deployKeyVault) {
  name: 'keyVault-${region.location}'
  scope: resourceGroup('${abbr.resourceGroup}-${abbr.service}-${managementResourceGroup}-${region.properties.shortName}')
  dependsOn: [
    coreResourceGroups
  ]
  params: {
    tags: tags
    abbr: abbr
    regionShortName: region.properties.shortName
  }
}]
