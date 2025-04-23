// Target the subscription so that we can deploy images into multiple regions
targetScope = 'subscription'

@description('An array of Azure regions to deploy resources into')
var regions = json(loadTextContent('./params/regions.json'))

@description('Abbreviations for resource names')
var abbr = json(loadTextContent('./params/abbreviations.json'))

@description('Image customisers')
var imageCustomisers = json(loadTextContent('./params/customImages.json'))

@description('The UPN of the user deploying the environment - must pass via the CLI')
param upn string

@description('Additional tag values')
var tagsFile = json(loadTextContent('./params/tags.json'))

@description('Union of tags with the user\'s upn')
var tags = union(tagsFile, {
  LastUpdateBy: upn
})

// Filter for regions that are enabled for deployment
var regionsToDeploy = filter(regions, region => region.deployRegion == true)

// Create an image definition for each region
module customImages 'modules/loopImageBuilder.bicep' = [for region in regionsToDeploy: if(region.customImages.deployImages) {
  name: 'customImage-${region.location}'
  scope: resourceGroup('${abbr.resourceGroup}-${abbr.service}-${region.customImages.resourceGroup}-${region.properties.shortName}')
  params: {
    location: region.location
    abbr: abbr
    tags: tags
    managedIdentityName: '${abbr.identity}${abbr.service}Images${region.location}'
    computeGalleryName: '${abbr.computeGallery}${abbr.service}Images${region.location}'
    images: region.customImages.images
    language: region.properties.language
    imageCustomisers: imageCustomisers
    replicationRegions: region.customImages.replicationRegions
  }
}]
