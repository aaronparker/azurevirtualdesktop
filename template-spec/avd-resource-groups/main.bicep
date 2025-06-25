// Target the subscription to deploy resource groups into
targetScope = 'subscription'

@description('The region or location the network resources will be deployed into.')
@allowed([
  'eastus'
  'westus2'
  'westus3'
  'centralus'
  'southcentralus'
  'brazilsouth'
  'australiaeast'
  'australiasoutheast'
  'uksouth'
  'southindia'
])
param location string

@description('The list of allowed regions to create resource groups in.')
var regions = {
  eastus: 'eus'
  westus2: 'wus2'
  westus3: 'wus3'
  centralus: 'cus'
  southcentralus: 'scus'
  brazilsouth: 'brs'
  australiaeast: 'aue'
  australiasoutheast: 'ause'
  uksouth: 'uks'
  southindia: 'sind'
}

@description('The list of resource groups to create for the Azure Virtual Desktop deployment.')
var resourceGroups = [
  {
    name: 'host-pool01'
    description: 'Azure Virtual Desktop host pool resources.'
  }
  {
    name: 'host-pool02'
    description: 'Azure Virtual Desktop host pool resources.'
  }
  {
    name: 'images'
    description: 'Azure Virtual Desktop and Windows 365 image resources.'
  }
  {
    name: 'network'
    description: 'Virtual network resources for AVD and W365.'
  }
  {
    name: 'service-objects'
    description: 'Azure Virtual Desktop management resources.'
  }
]

@description('Enter your email address. This will be included in the Owner tag on the target resources.')
param email string

@description('The date and time the resources are being deployed.')
param date string = utcNow('yyyy-MM-dd HH:mm:ss')

@description('Tags to be applied to all resources created by this template.')
param tags object = {
  Application: 'Nerdio Manager'
  Criticality: 'Medium'
  Environment: 'Demo'
  LastUpdateBy: email
  LastUpdateDate: date
  Type: 'Virtual desktops'
}

@description('The name of the service being deployed, used for abbreviations in resource names.')
@maxLength(4)
@minLength(2)
param service string = 'Avd'

// Loop through the resource module for each region to create core resource groups
module createResourceGroups 'resourceGroups.bicep' = [
  for group in resourceGroups: {
    name: 'resourceGroup-${group.name}-${location}'
    params: {
      name: 'rg-${service}-${group.name}-${regions[location]}'
      location: location
      tags: union(tags, {
        Function: group.description
      })
    }
  }
]
