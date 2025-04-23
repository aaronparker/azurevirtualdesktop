targetScope = 'subscription'

@description('Array of actions for the roleDefinition')
param actions array

@description('Array of notActions for the roleDefinition')
param notActions array = []

@description('Friendly name of the role definition')
param roleName string

@description('Detailed description of the role definition')
param roleDescription string

var roleDefName = guid(subscription().id, string(actions), string(notActions))

// Check whether the role already exists
resource roleDefExisting 'Microsoft.Authorization/roleDefinitions@2022-04-01' existing = {
  name: roleDefName
}

// Create the role if it doesn't already exist
resource roleDef 'Microsoft.Authorization/roleDefinitions@2022-04-01' = if (!empty(roleDefExisting.id)) {
  name: roleDefName
  properties: {
    roleName: roleName
    description: roleDescription
    type: 'customRole'
    permissions: [
      {
        actions: actions
        notActions: notActions
      }
    ]
    assignableScopes: [
      subscription().id
    ]
  }
}
