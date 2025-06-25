targetScope = 'subscription'

@description('The display name of the policy.')
param policyDisplayName string = 'Enforce Resource Group Naming Convention'

resource policyDefinition 'Microsoft.Authorization/policyDefinitions@2025-01-01' = {
  name: 'enforce-rg-naming-convention'
  properties: {
    displayName: policyDisplayName
    description: 'Requires resource group names to start with "rg-" and be lowercase characters.'
    mode: 'Indexed'
    policyRule: {
      if: {
        field: 'type'
        equals: 'Microsoft.Resources/subscriptions/resourceGroups'
      }
      then: {
        effect: 'deny'
        details: {
          type: 'Microsoft.Resources/subscriptions/resourceGroups'
          pattern: '^rg-(?=[0-9a-z_]).*$'
          reason: 'Resource group name must start with "rg-" and be lowercase characters.'
        }
      }
      else: {
        effect: 'deny'
        details: {
          type: 'Microsoft.Resources/subscriptions/resourceGroups'
        }
      }
    }
    parameters: {}
    metadata: {
      category: 'Resource Group'
      version: '1.0.0'
    }
  }
}

resource policyAssignment 'Microsoft.Authorization/policyAssignments@2025-01-01' = {
  name: 'enforce-rg-naming-convention-assignment'
  properties: {
    displayName: policyDisplayName
    policyDefinitionId: policyDefinition.id
  }
}
