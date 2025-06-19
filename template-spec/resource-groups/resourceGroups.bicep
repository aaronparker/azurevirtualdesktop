// Resource groups need to target the subscription
targetScope = 'subscription'

// Location for these resource groups
@description('The Azure region to deploy the subscriptions into')
param location string

@description('The resource group name')
param name string

@description('Tags to be applied to all resources created by this template.')
param tags object

// Create the resource group
resource createResourceGroup 'Microsoft.Resources/resourceGroups@2024-11-01' = {
  name: name
  location: location
  tags: tags
}
