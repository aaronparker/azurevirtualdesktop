targetScope = 'resourceGroup'

@description('The region to deploy resources into')
param location string = resourceGroup().location

@description('The metadata region for the workspace object')
param metaDataLocation string

@description('Workspace name.')
param workspaceName string

@description('Workspace name friendly name. This is displayed in the client user interface.')
param workspaceFriendlyName string = 'Australia East'

@description('Description for the workspace.')
param workspaceDescription string = 'Azure Virtual Desktop workspace for ${location}'

@description('Tags object to be combined with object specific tags')
param tags object

@description('Combine the tags parameters into object specific tag values')
param tagsUnion object = union (tags, {
  Application: resourceGroup().tags.Application
  LastUpdateDate: utcNow('yyyy-M-dd HH:mm:ss')
  Criticality: resourceGroup().tags.Criticality
  Function: 'AVD workspace'
  Type: resourceGroup().tags.Type
})

// Create the AVD workspace
resource avdWorkspace 'Microsoft.DesktopVirtualization/workspaces@2024-04-03' = {
  name: workspaceName
  location: ((!empty(metaDataLocation)) ? metaDataLocation : resourceGroup().location)
  tags: tagsUnion
  properties: {
    applicationGroupReferences: []
    description: workspaceDescription
    friendlyName: workspaceFriendlyName
    publicNetworkAccess: 'Enabled'
  }
}

output workspace object = avdWorkspace
