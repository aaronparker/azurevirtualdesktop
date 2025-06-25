targetScope = 'subscription'

@description('The display name of the policy.')
param policyDisplayName string = 'Allowed locations for resource groups'

@description('List of allowed locations for resource groups.')
param listOfAllowedLocations array = [
  'eastus'
  'westus2'
  'westus3'
  'southcentralus'
  'brazilsouth'
  'australiaeast'
  'uksouth'
  'southindia'
]

// Return the policy definition id for the allowed locations policy
resource policyDef 'Microsoft.Authorization/policyDefinitions@2025-01-01' existing = {
  name: policyDisplayName
}

// Assign the policy to the subscription with the allowed locations
resource policyAssignment 'Microsoft.Authorization/policyAssignments@2025-01-01' = {
  name: 'allowed-locations-resource-groups'
  properties: {
    displayName: policyDisplayName
    policyDefinitionId: policyDef.id
    parameters: {
      listOfAllowedLocations: {
        value: listOfAllowedLocations
      }
    }
  }
}
