// Resource groups need to target the subscription
targetScope = 'subscription'

// Location for these resource groups
@description('The Azure region to deploy the subscriptions into')
param location string

@description('The short name for the region')
param regionShortName string

@description('Abbreviations for resource names')
param abbr object

// Parameters that will be used in tags
@description('Value to apply to the LastUpdateDate date tag on the object.')
param LastUpdateDate string = utcNow('yyyy-M-dd HH:mm:ss')

@description('Tags object to be combined with object specific tags')
param tags object

// Resource group names
@description('An array of resource group names with function and criticality tags')
param resourceGroups array

// Loop through the resource groups for this location, including tags
resource createResourceGroups 'Microsoft.Resources/resourceGroups@2024-11-01' = [for group in resourceGroups: {
  name: ((!empty(group.resourceGroupLiteralName)) ? group.resourceGroupLiteralName : '${abbr.resourceGroup}-${abbr.service}-${group.name}-${regionShortName}')
  location: location
  tags: union (tags, {
    LastUpdateDate: LastUpdateDate
    Criticality: group.criticality
    Function: group.function
    Type: group.type
  })
}]
