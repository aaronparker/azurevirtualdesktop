targetScope = 'resourceGroup'

@description('Name of the Log Analytics workspace.')
param workspaceName string

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

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: workspaceName
  location: resourceGroup().location
  tags: tagsUnion
  //etag: 'string'
  // identity: {
  //   type: 'string'
  //   userAssignedIdentities: {}
  // }
  properties: {
    //defaultDataCollectionRuleResourceId: 'string'
    // features: {
    //   clusterResourceId: 'string'
    //   disableLocalAuth: bool
    //   enableDataExport: bool
    //   enableLogAccessUsingOnlyResourcePermissions: bool
    //   immediatePurgeDataOn30Days: bool
    // }
    //forceCmkForQuery: false
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
    retentionInDays: 30
    sku: {
      //capacityReservationLevel: int
      name: 'pergb2018'
    }
    workspaceCapping: {
      dailyQuotaGb: -1
    }
  }
}
