targetScope = 'resourceGroup'

@description('The region to deploy resources into.')
param location string = resourceGroup().location

@description('Abbreviations for resource names')
param abbr object

@description('Managed identity with permissions to build custom images.')
param managedIdentityName string

@description('Name of the compute gallery to store the image in.')
param computeGalleryName string

@description('Regions to replicate the image to.')
param replicationRegions array
var replicationRegionsUnion = union(replicationRegions, [location])

@description('Language code for the image.')
param language string

@description('Tags object to be combined with object specific tags')
param tags object

@description('An array of image templates to create')
param images array

@description('Image customisers')
param imageCustomisers object

module customImage 'imageBuilder.bicep' = [for (image, i) in images: {
  name: 'image-${image.publisher}-${image.offer}-${image.sku}-${language}-${i}'
  scope: resourceGroup()
  params: {
    location: location
    //resourceGroupName: resourceGroup().name
    tags: union (tags, {
      AVD_IMAGE_TEMPLATE: 'AVD_IMAGE_TEMPLATE'
      Application: resourceGroup().tags.Application
      Criticality: resourceGroup().tags.Criticality
      Function: image.imageDescription
      Type: resourceGroup().tags.Type
    })
    abbr: abbr
    managedIdentityName: managedIdentityName
    computeGalleryName: computeGalleryName
    offer: image.offer
    publisher: image.publisher
    sku: image.sku
    language: language
    index: i
    replicationRegions: replicationRegionsUnion
    imageCustomisers: imageCustomisers[image.customisers]
  }
}]
