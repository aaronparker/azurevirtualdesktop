targetScope = 'subscription'

@description('The region to deploy resources into')
param location string = 'australiaeast'

@description('Abbreviations for resource names')
var abbr = json(loadTextContent('./params/abbreviations.json'))

@description('An array of Azure regions to deploy resources into')
var regions = json(loadTextContent('./params/regions.json'))

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

module networkManager 'modules/networkManager.bicep' = [for region in regionsToDeploy: {
  name: 'networkManager-${location}'
  scope: resourceGroup('${abbr.resourceGroup}-${abbr.service}-${region.network.resourceGroup}-${region.properties.shortName}')
  params: {
    location: location
    tags: tags
    networkManagerName: '${abbr.networkManager}-${abbr.service}Network-${location}'
    networkGroupName: '${abbr.service}-NetworkGroup'
    service: abbr.service
    subscriptionId: [
      subscription().id
    ]
    applicationTag: tags.Application
  }
}]
