@description('Location of the network security group')
param location string = resourceGroup().location

@description('Name of the network security group')
param nsgName string

@description('Array of security rules to be associated with the network security group')
param securityRules array

@description('Tags to be associated with the network security group')
param tags object

var securityRuleArray = [for (securityRule, i) in securityRules: {
  name: securityRule.name
  properties: {
    access: securityRule.properties.access
    description: securityRule.properties.?description ?? ''
    destinationAddressPrefix: securityRule.properties.?destinationAddressPrefix ?? ''
    destinationAddressPrefixes: securityRule.properties.?destinationAddressPrefixes ?? []
    destinationApplicationSecurityGroups: securityRule.properties.?destinationApplicationSecurityGroups ?? []
    destinationPortRange: securityRule.properties.?destinationPortRange ?? ''
    destinationPortRanges: securityRule.properties.?destinationPortRanges ?? []
    direction: securityRule.properties.direction
    priority: securityRule.properties.priority
    protocol: securityRule.properties.protocol
    sourceAddressPrefix: securityRule.properties.?sourceAddressPrefix ?? ''
    sourceAddressPrefixes: securityRule.properties.?sourceAddressPrefixes ?? []
    sourceApplicationSecurityGroups: securityRule.properties.?sourceApplicationSecurityGroups ?? []
    sourcePortRange: securityRule.properties.?sourcePortRange ?? ''
    sourcePortRanges: securityRule.properties.?sourcePortRanges ?? []
  }
}]

resource nsg 'Microsoft.Network/networkSecurityGroups@2024-05-01' = {
  name: nsgName
  location: location
  tags: tags
  properties: {
    securityRules: securityRuleArray
  }
}
