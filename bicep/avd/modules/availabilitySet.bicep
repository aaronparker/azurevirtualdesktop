targetScope = 'resourceGroup'

@description('The Azure region short name to deploy the resources')
@maxLength(4)
param regionShortName string

@description('Abbreviations for resource names')
param abbr object

@description('An array of host pools to create')
param hostPool object

@description('Tags object to be combined with object specific tags')
param tags object

@description('Combine the tags parameters into object specific tag values')
param tagsUnion object = union (tags, {
  Application: resourceGroup().tags.Application
  LastUpdateDate: utcNow('yyyy-M-dd HH:mm:ss')
  Criticality: resourceGroup().tags.Criticality
  Function: hostPool.function
  Type: resourceGroup().tags.Type
})

resource availabilitySets 'Microsoft.Compute/availabilitySets@2024-11-01' = {
  name: '${abbr.availSet}-${abbr.service}-${hostPool.name}-${regionShortName}'
  location: resourceGroup().location
  tags: tagsUnion
  properties: {
    platformUpdateDomainCount: 5
    platformFaultDomainCount: 2
  }
  sku: {
    name: 'Aligned'
  }
}
