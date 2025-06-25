// Target the subscription to deploy resource groups into
targetScope = 'subscription'

@description('The region or location the resource group will be deployed into.')
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

@description('Enter your email address. This will be included in the Owner tag on the target resources.')
param email string

@description('A short name of the service being deployed, used for abbreviations in resource names.')
@maxLength(4)
@minLength(2)
param service string = 'Avd'

@description('.')
param name string = 'avd'

@description('The name of the application being deployed, used for tagging resources.')
param application string

@allowed(['High', 'Medium', 'Low'])
param criticality string = 'Medium'

@allowed([
  'Production'
  'Test'
  'Dev'
  'Demo'
])
param environment string = 'Demo'

@description('The name of the resource group to create.')
param type string

@description('The name of the resource group to create.')
param function string

@description('The date and time the resources are being deployed.')
param date string = utcNow('yyyy-MM-dd HH:mm:ss')

@description('Tags to be applied to all resources created by this template.')
var tags = {
  Application: application
  Criticality: criticality
  Environment: environment
  Function: function
  LastUpdateBy: email
  LastUpdateDate: date
  Type: type
}

// Create the resource group
resource createResourceGroup 'Microsoft.Resources/resourceGroups@2024-11-01' = {
  name: 'rg-${service}-${name}-${regions[location]}'
  location: location
  tags: tags
}
