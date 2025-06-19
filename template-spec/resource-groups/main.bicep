// Target the subscription to deploy resource groups into
targetScope = 'subscription'

@description('The region or location the network resources will be deployed into.')
param location string

@description('The list of regions to create resource groups in.')
var regions object = {
  eastus: 'eus'
  westus2: 'wus2'
  westus3: 'wus3'
  australiaeast: 'aus'
  australiasoutheast: 'ause'
  uksouth: 'uks'
}

@description('The list of resource groups to create for the Azure Virtual Desktop deployment.')
var resourceGroups array = [
  {
    name: 'HostPool01'
    description: 'Azure Virtual Desktop host pool resources.'
  }
  {
    name: 'HostPool02'
    description: 'Azure Virtual Desktop host pool resources.'
  }
  {
    name: 'Images'
    description: 'Azure Virtual Desktop and Windows 365 image resources.'
  }
  {
    name: 'ServiceObjects'
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
