
@description('The Azure region to deploy the resources')
param location string = resourceGroup().location

@description('The Azure region short name to deploy the resources')
@maxLength(4)
param regionShortName string

@description('The metadata region for the host pool and application group objects')
param metaDataLocation string

@description('Abbreviations for resource names')
param abbr object

@description('Tags object to be combined with object specific tags')
param tags object

@description('An array of host pools to create')
param hostPools array

@description('The RDP properties for the host pool')
param customRdpProperty string

@description('The time zone for the host pool')
param timeZone string

@description('The scaling plan schedules for the host pool')
param scalingPlanSchedules array

module avdHostPools 'avdHostPool.bicep' = [for hostPool in hostPools: {
  name: 'hostPool-${hostPool.name}'
  scope: resourceGroup()
  params: {
    abbr: abbr
    tags: tags
    hostPool: hostPool
    hostPoolName: '${abbr.hostPool}-${abbr.service}-${hostPool.name}-${hostPool.type}-${regionShortName}'
    customRdpProperty: customRdpProperty
    metaDataLocation: ((empty(metaDataLocation)) ? location : metaDataLocation)
    regionShortName: regionShortName
    timeZone: timeZone
  }
}]

module avdAvailSet 'availabilitySet.bicep' = [for hostPool in hostPools: {
  name: 'avail-${hostPool.name}'
  scope: resourceGroup('${abbr.resourceGroup}-${abbr.service}-${hostPool.name}-${regionShortName}')
  params: {
    abbr: abbr
    tags: tags
    hostPool: hostPool
    regionShortName: regionShortName
  }
}]

// module avdScalingPlans 'scalingPlans.bicep' = [for hostPool in hostPools: {
//   name: 'scalingPlan-${hostPool.name}'
//   scope: resourceGroup('${abbr.resourceGroup}-${abbr.service}-${hostPool.name}-${regionShortName}')
//   params: {
//     abbr: abbr
//     tags: tags
//     scalingPlanName: '${abbr.scalingPlan}-${hostPool.type}-${abbr.service}-${hostPool.name}-${location}'
//     schedules: scalingPlanSchedules
//     hostPool: hostPool
//     timeZone: timeZone
//     metaDataLocation: ((empty(metaDataLocation)) ? location : metaDataLocation)
//   }
// }]
