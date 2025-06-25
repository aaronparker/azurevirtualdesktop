targetScope = 'subscription'

@description('The display name of the policy.')
param policyDisplayName string = 'Allowed locations for resource groups'

@description('The ID of the policy definition for "Allowed locations for resource groups"')
param policyDefinitionId string = '/providers/Microsoft.Authorization/policyDefinitions/7b0c1f8d-2c3e-4f5a-9b6d-8f0c1f8d2c3e'

@description('List of allowed locations for resource groups.')
param listOfAllowedLocations array = [
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
]

resource policyAssignment 'Microsoft.Authorization/policyAssignments@2025-01-01' = {
  name: 'allowed-locations-resource-groups'
  properties: {
    displayName: policyDisplayName
    policyDefinitionId: policyDefinitionId
    parameters: {
      listOfAllowedLocations: {
        value: listOfAllowedLocations
      }
    }
  }
}
