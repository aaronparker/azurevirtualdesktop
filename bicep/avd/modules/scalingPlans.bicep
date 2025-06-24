targetScope = 'resourceGroup'

@description('The region to deploy resources into')
param location string = resourceGroup().location

@description('The metadata region for the host pool and application group objects')
param metaDataLocation string

@description('Abbreviations for resource names')
param abbr object

@description('Tags object to be combined with object specific tags')
param tags object

@description('Combine the tags parameters into object specific tag values')
param tagsUnion object = union (tags, {
  Application: resourceGroup().tags.Application
  LastUpdateDate: utcNow('yyyy-M-dd HH:mm:ss')
  Criticality: resourceGroup().tags.Criticality
  Function: resourceGroup().tags.Function
  Type: resourceGroup().tags.Type
})

@description('An array of host pools to create')
param hostPool object

@description('The name of the Scaling plan to be created.')
param scalingPlanName string = '${abbr.scalingPlan}-${hostPool.type}-${hostPool.name}-${location}'

@description('The description of the Scaling plan to be created.')
param scalingPlanDescription string = ''

@description('The friendly name of the Scaling plan to be created.')
param friendlyName string = ''

@description('Scaling plan autoscaling triggers and Start/Stop actions will execute in the time zone selected.')
param timeZone string

@description('The schedules of the Scaling plan to be created.')
param schedules array

@description('The array of host pool resourceId with enabled flag.')
param hostpoolReferences array = []

@description('The name of the tag associated with the VMs that will be excluded from the Scaling plan.')
param exclusionTag string = ''

resource scalingPlan 'Microsoft.DesktopVirtualization/scalingPlans@2024-04-03' = {
  name: scalingPlanName
  location: ((empty(metaDataLocation)) ? resourceGroup().location : metaDataLocation)
  tags: tagsUnion
  properties: {
    friendlyName: friendlyName
    description: scalingPlanDescription
    hostPoolType: hostPool.type
    timeZone: timeZone
    exclusionTag: exclusionTag
    schedules: schedules
    hostPoolReferences: hostpoolReferences
  }
}

resource pooledSchedule 'Microsoft.DesktopVirtualization/scalingPlans/pooledSchedules@2024-04-03' = [for item in schedules: if (hostPool.type == 'Pooled') {
    parent: scalingPlan
    name: '${item.name}'
    properties: item
  }
]

resource personalSchedule 'Microsoft.DesktopVirtualization/scalingPlans/personalSchedules@2024-04-03' = [for item in schedules: if (hostPool.type == 'Personal') {
    parent: scalingPlan
    name: '${item.name}'
    properties: item
  }
]
