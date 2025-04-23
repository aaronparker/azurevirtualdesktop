targetScope = 'resourceGroup'

@description('The metadata region for the host pool and application group objects')
param metaDataLocation string

@description('The Azure region short name to deploy the resources')
@maxLength(4)
param regionShortName string

@description('Abbreviations for resource names')
param abbr object

@description('An array of host pools to create')
param hostPool object

// Create the host pool name
@description('The host pool name')
param hostPoolName string = '${abbr.hostPool}-${hostPool.name}-${hostPool.type}-${regionShortName}'

@description('The RDP properties for the host pool')
param customRdpProperty string

@description('The time zone for the host pool')
param timeZone string

@description('Tags object to be combined with object specific tags')
param tags object

@description('Combine the tags parameters into object specific tag values')
param tagsUnion object = union (tags, {
  Application: resourceGroup().tags.Application
  LastUpdateDate: utcNow('yyyy-M-dd')
  Criticality: resourceGroup().tags.Criticality
  Function: hostPool.function
  Type: hostPool.type
})

// Create the host pool
resource avdHostPool 'Microsoft.DesktopVirtualization/hostPools@2024-04-03' = {
  name: hostPoolName
  location: ((empty(metaDataLocation)) ? resourceGroup().location : metaDataLocation)
  tags: tagsUnion
  // sku: {
  //   capacity: 0
  //   family: 'string'
  //   name: 'string'
  //   size: 'string'
  //   tier: 'string'
  // }
  // kind: 'string'
  // identity: {
  //   type: 'SystemAssigned'
  // }
  // managedBy: 'string'
  // plan: {
  //   name: 'string'
  //   product: 'string'
  //   promotionCode: 'string'
  //   publisher: 'string'
  //   version: 'string'
  // }
  properties: {
    agentUpdate: {
      maintenanceWindows: hostPool.maintenanceWindows
      maintenanceWindowTimeZone: timeZone
      type: 'Scheduled'
      useSessionHostLocalTime: false
    }
    customRdpProperty: customRdpProperty
    description: hostPool.description
    friendlyName: hostPool.friendlyName
    hostPoolType: hostPool.type
    loadBalancerType: hostPool.loadBalancerType
    maxSessionLimit: hostPool.maxSessionLimit
    personalDesktopAssignmentType: hostPool.assignmentType
    preferredAppGroupType: hostPool.appGroupType
    publicNetworkAccess: 'Enabled' //((hostPool.publicNetworkAccess) ? hostPool.publicNetworkAccess : 'Enabled')
    // registrationInfo: {
    //   expirationTime: 'string'
    //   registrationTokenOperation: 'string'
    //   token: 'string'
    // }
    ring: 0
    startVMOnConnect: true
    validationEnvironment: false
    //vmTemplate: 'string'
  }
}

// Create an application group for this host pool
resource appGroup 'Microsoft.DesktopVirtualization/applicationGroups@2023-09-05' = {
  name: '${hostPoolName}-dag'
  location: ((empty(metaDataLocation)) ? resourceGroup().location : metaDataLocation)
  tags: tagsUnion
  kind: 'Desktop'
  properties: {
      friendlyName: hostPool.appGroupFriendlyName
      applicationGroupType: hostPool.appGroupType
      description: hostPool.description
      hostPoolArmPath: avdHostPool.id
      showInFeed: true
  }
}
