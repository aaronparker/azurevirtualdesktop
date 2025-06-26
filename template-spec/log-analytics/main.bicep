// Target the resource group to deploy network resources into
targetScope = 'resourceGroup'

@description('The region or location the network resources will be deployed into.')
var location = resourceGroup().location

@description('Enter your email address. This will be included in the Owner tag on the target resources.')
param email string

@description('The name of the service being deployed, used for abbreviations in resource names.')
@maxLength(24)
@minLength(3)
param name string

@description('The date and time the resources are being deployed.')
param date string = utcNow('yyyy-MM-dd HH:mm:ss')

@description('Tags to be applied to all resources created by this template.')
var tags = {
  Application: resourceGroup().tags.Application
  Criticality: resourceGroup().tags.Criticality
  Environment: resourceGroup().tags.Environment
  Function: resourceGroup().tags.Function
  LastUpdateBy: email
  LastUpdateDate: date
  Type: resourceGroup().tags.Type
}

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

// Create the Log Analytics workspace resource
resource logAnalyticsWorkspace 'Microsoft.OperationalInsights/workspaces@2025-02-01' = {
  name: 'log-${name}-${regions[location]}'
  location: location
  tags: tags
  // etag: 'string'
  // identity: {
  //   type: 'string'
  //   userAssignedIdentities: {
  //     {customized property}: {}
  //   }
  // }
  properties: {
    //defaultDataCollectionRuleResourceId: 'string'
    //failover: {}
    features: {
      // clusterResourceId: 'string'
      disableLocalAuth: false
      enableDataExport: false
      enableLogAccessUsingOnlyResourcePermissions: false
      immediatePurgeDataOn30Days: false
    }
    forceCmkForQuery: false
    publicNetworkAccessForIngestion: 'Enabled'
    publicNetworkAccessForQuery: 'Enabled'
    // replication: {
    //   enabled: false
    //   location: ''
    // }
    retentionInDays: 30
    sku: {
      // capacityReservationLevel: 0
      name: 'pergb2018'
    }
    workspaceCapping: {
      dailyQuotaGb: -1
    }
  }
}
