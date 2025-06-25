targetScope = 'subscription'

@description('The display name of the policy.')
param policyDisplayName string = 'Require and validate specific tags on all resource groups'

resource tagPolicy 'Microsoft.Authorization/policyDefinitions@2025-01-01' = {
  name: 'enforce-required-tags-on-rgs'
  properties: {
    policyType: 'Custom'
    mode: 'Indexed'
    displayName: policyDisplayName
    description: 'Ensures all resource groups have required tags with validated values and formats.'
    parameters: {}
    policyRule: {
      if: {
        field: 'type'
        equals: 'Microsoft.Resources/subscriptions/resourceGroups'
      }
      then: {
        effect: 'deny'
        details: {
          evaluation: 'AllOf'
          allOf: [
            // Application tag not null
            {
              field: 'tags.Application'
              exists: true
            }
            {
              field: 'tags.Application'
              notEquals: ''
            }
            // Criticality tag allowed values
            {
              field: 'tags.Criticality'
              in: [
                'High'
                'Medium'
                'Low'
              ]
            }
            // Environment tag allowed values
            {
              field: 'tags.Environment'
              in: [
                'Production'
                'Demo'
                'Development'
                'Test'
              ]
            }
            // Function tag not null
            {
              field: 'tags.Function'
              exists: true
            }
            {
              field: 'tags.Function'
              notEquals: ''
            }
            // LastUpdateBy tag email validation
            {
              field: 'tags.LastUpdateBy'
              match: '^.*@getnerdio\\.com$'
            }
            // LastUpdateDate tag date format validation
            {
              field: 'tags.LastUpdateDate'
              match: '^\\d{4}-\\d{2}-\\d{2}$'
            }
            // Type tag not null
            {
              field: 'tags.Type'
              exists: true
            }
            {
              field: 'tags.Type'
              notEquals: ''
            }
          ]
        }
      }
    }
  }
}

resource tagPolicyAssignment 'Microsoft.Authorization/policyAssignments@2025-01-01' = {
  name: 'enforce-required-tags-on-rgs-assignment'
  properties: {
    displayName: policyDisplayName
    policyDefinitionId: tagPolicy.id
  }
}
