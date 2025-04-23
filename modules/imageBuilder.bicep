targetScope = 'resourceGroup'

@description('The region to deploy resources into.')
param location string = resourceGroup().location

// @description('The name of the resource group to deploy resources into')
// param resourceGroupName string

@description('Abbreviations for resource names')
param abbr object

@description('The name for the Azure compute gallery.')
param computeGalleryName string

@description('Image publisher.')
param publisher string

@description('Image offer.')
param offer string

@description('Image SKU.')
param sku string

@description('Index of this image.')
param index int

@description('Language code for the image.')
param language string

@description('Image template name.')
var imageTemplateName = '${abbr.imgTemplate}-${abbr.service}-${sku}-${language}-0${index + 1}'
var imageOutputName = '${abbr.service}-${sku}-${language}-0${index + 1}'

@description('Managed identity with permissions to build custom images.')
param managedIdentityName string

@description('Regions to replicate the image to.')
param replicationRegions array

@description('An array of customisers to run in the custom image.')
param imageCustomisers array

@description('Tags object to be combined with object specific tags')
param tags object

@description('Combine the tags parameters into object specific tag values')
param tagsUnion object = union (tags, {
  LastUpdateDate: utcNow('yyyy-M-dd')
})

resource computeGallery 'Microsoft.Compute/galleries@2023-07-03' existing = {
  name: computeGalleryName
}

// Create the image gallery
resource galleryImage 'Microsoft.Compute/galleries/images@2023-07-03' = {
  name: '${publisher}-${offer}-${sku}-${language}'
  parent: computeGallery
  location: location
  tags: tagsUnion
  properties: {
    description: '${publisher}-${offer}-${sku}'
    osType: 'Windows'
    osState: 'Generalized'
    hyperVGeneration: 'V2'
    identifier: {
      publisher: publisher
      offer: offer
      sku: sku
    }
  }
}

// Get the image if it already exists
resource existingImageTemplate 'Microsoft.VirtualMachineImages/imageTemplates@2024-02-01' existing = {
  name: imageTemplateName
}

// Create the image template if the image does not exist - we can't update an existing image
resource imageTemplate 'Microsoft.VirtualMachineImages/imageTemplates@2024-02-01' = if (!empty(existingImageTemplate.id)) {
  name: imageTemplateName
  location: location
  tags: tagsUnion
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
        '${resourceId('Microsoft.ManagedIdentity/userAssignedIdentities', managedIdentityName)}': {}
    }
  }
  properties: {
    // stagingResourceGroup: resourceGroup().id // must be an empty resource group
    source: {
      offer: offer
      publisher: publisher
      sku: sku
      type: 'PlatformImage'
      version: 'latest'
    }
    buildTimeoutInMinutes: 240
    optimize: {
      vmBoot: {
        state: 'Enabled'
      }
    }
    vmProfile: {
      vmSize: 'Standard_D4ads_v5'
      osDiskSizeGB: 127
    }
    distribute: [
      {
        artifactTags: {
          Application: resourceGroup().tags.Application
          Criticality: resourceGroup().tags.Criticality
          Function: tags.Function
          Type: '${publisher}-${offer}-${sku}'
        }
        runOutputName: imageOutputName
        type: 'SharedImage'
        excludeFromLatest: false
        galleryImageId: galleryImage.id
        replicationRegions: replicationRegions
        storageAccountType: 'Standard_LRS'
      }
    ]
    customize: imageCustomisers
  }
}
