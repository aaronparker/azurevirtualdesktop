// Resource groups need to target the subscription
targetScope = 'subscription'

// @description('Azure Virtual Desktop role definitions')
var roleDefinitions = json(loadTextContent('./params/roles.json'))

// Create custom roles on the subscription
module roles 'modules/roleDefinitions.bicep' = [for role in roleDefinitions: {
  name: 'roleDef${guid(role.name)}'
  params: {
    roleName: role.name
    roleDescription: role.description
    actions: role.permissions
    notActions: role.notActions
  }
}]
