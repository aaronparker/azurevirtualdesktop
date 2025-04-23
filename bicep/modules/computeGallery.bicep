targetScope = 'resourceGroup'

@description('The region to deploy resources into')
param location string = resourceGroup().location

@description('Abbreviations for resource names')
param abbr object

@description('The regional / locale settings applied to the image')
param imageLanguage string

@description('Description for the compute gallery')
param galleryDescription string = 'Azure Virtual Desktop images for ${location}'

@description('The images to add to the gallery')
param images array

@description('Tags object to be combined with object specific tags')
param tags object

@description('Combine the tags parameters into object specific tag values')
param tagsUnion object = union (tags, {
  Application: resourceGroup().tags.Application
  LastUpdateDate: utcNow('yyyy-M-dd')
  Criticality: resourceGroup().tags.Criticality
  Function: resourceGroup().tags.Function
  Type: resourceGroup().tags.Type
  Language: imageLanguage
})

@description('The date the gallery was last updated')
param LastUpdateDate string = utcNow('yyyy-M-dd')


// Create a managed identity to enable image builder access to target resource groups
resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: '${abbr.identity}${abbr.service}Images${location}'
  location: location
  tags: tagsUnion
}

resource imageGallery 'Microsoft.Compute/galleries@2023-07-03' = {
  name: '${abbr.computeGallery}${abbr.service}Images${location}'
  location: location
  tags: tagsUnion
  properties: {
    description: galleryDescription
  }
}

// Create the image definition
resource imageDefinition 'Microsoft.Compute/galleries/images@2023-07-03' = [for image in images: {
  name: '${image.publisher}-${image.offer}-${image.sku}-${imageLanguage}'
  location: location
  tags: union (tags, {
    Application: resourceGroup().tags.Application
    LastUpdateDate: LastUpdateDate
    Criticality: resourceGroup().tags.Criticality
    Function: image.imageDescription
    Type: resourceGroup().tags.Type
    Language: imageLanguage
  })
  parent: imageGallery
  properties: {
    architecture: 'x64'
    description: image.imageDescription
    disallowed: {
      diskTypes: []
    }
    features: [
      {
        name: 'SecurityType'
        value: 'TrustedLaunch'
      }
      {
        name: 'IsAcceleratedNetworkSupported'
        value: 'true'
      }
    ]
    hyperVGeneration: 'V2'
    identifier: {
      offer: image.offer
      publisher: image.publisher
      sku: image.sku
    }
    osState: 'Generalized'
    osType: 'Windows'
    recommended: {
      memory: {
        min: 8
        max: 64
      }
      vCPUs: {
        min: 2
        max: 32
      }
    }
  }
}]
