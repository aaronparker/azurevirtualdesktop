targetScope = 'resourceGroup'

@description('The region to deploy resources into.')
param location string

@description('The name of the virtual network')
param vnetName string

@description('The name of the network security group for host pools.')
param hostPoolNsg string

@description('Security rules to be applied to network security groups.')
param nsgRules array

@description('The address space for the virtual network')
param addressSpace string

@description('The DNS servers for the virtual network. If not specified, Azure-provided DNS servers will be used')
param dnsServers array

// Leave a gap for the GatewaySubnet
@description('An array of subnet names and IP ranges.')
param subnets array

@description('An array of paired regions for service endpoints.')
param endpointsLocation array = [
  '${location}'
]

@description('An array of service endpoints to create.')
var serviceEndpoints = [
  {
    service: 'Microsoft.Storage'
    locations: endpointsLocation
  }
  {
    service: 'Microsoft.KeyVault'
    locations: endpointsLocation
  }
]

@description('Name of the NAT gateway public IP.')
param publicIpName string

@description('Name of the NAT gateway.')
param natGatewayName string

@description('Specify whether the NAT gateway will be created.')
param deployNatGateway bool

@description('The private DNS zone name.')
var privateDNSZoneName = 'privatelink.file.${environment().suffixes.storage}'

@description('The name of the route table')
param routeTableName string

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

// Build a variable for NSG security rules
var securityRuleArray = [for (securityRule, i) in nsgRules: {
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
    //priority: securityRule.properties.priority
    priority: 100 + (10 * i)
    protocol: securityRule.properties.protocol
    sourceAddressPrefix: securityRule.properties.?sourceAddressPrefix ?? ''
    sourceAddressPrefixes: securityRule.properties.?sourceAddressPrefixes ?? []
    sourceApplicationSecurityGroups: securityRule.properties.?sourceApplicationSecurityGroups ?? []
    sourcePortRange: securityRule.properties.?sourcePortRange ?? ''
    sourcePortRanges: securityRule.properties.?sourcePortRanges ?? []
  }
}]

resource nsg 'Microsoft.Network/networkSecurityGroups@2024-05-01' = {
  name: hostPoolNsg
  location: location
  tags: tagsUnion
  properties: {
    securityRules: securityRuleArray
  }
}

// Create a public IP for the NAT gateway
resource publicip 'Microsoft.Network/publicIPAddresses@2024-05-01' = if (deployNatGateway) {
  name: publicIpName
  location: location
  tags: tagsUnion
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAddressVersion: 'IPv4'
    publicIPAllocationMethod: 'Static'
    idleTimeoutInMinutes: 4
  }
}

// Create the NAT gateway, and assign the public IP
resource natgateway 'Microsoft.Network/natGateways@2024-05-01' = if (deployNatGateway) {
  name: natGatewayName
  location: location
  tags: tagsUnion
  sku: {
    name: 'Standard'
  }
  properties: {
    idleTimeoutInMinutes: 4
    publicIpAddresses: [
      {
        id: publicip.id
      }
    ]
  }
}

// Create the virtual network and subnets, assigning the NSG to all subnets, and assign the NAT gateway
resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: vnetName
  location: location
  tags: tagsUnion
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressSpace
      ]
    }
    dhcpOptions: {
      dnsServers: ((!empty(dnsServers)) ? dnsServers : null)
    }
    subnets: [for subnet in subnets: {
      name: subnet.name
      properties: {
        addressPrefix: subnet.subnetPrefix
        networkSecurityGroup: {
          id: nsg.id
        }
        natGateway: ((deployNatGateway) ? { id: natgateway.id } : null)
        serviceEndpoints: serviceEndpoints
        delegations: []
        // defaultOutboundAccess: true
        //privateEndpointNetworkPolicies: 'Disabled'
        privateLinkServiceNetworkPolicies: subnet.privateLinkService
      }
    }]
    virtualNetworkPeerings: []
    enableDdosProtection: false
  }
}

// Create the private DNS zone required for private endpoints
resource privateDNSZone 'Microsoft.Network/privateDnsZones@2024-06-01' = {
  name: privateDNSZoneName
  location: 'global'
  tags: tagsUnion

  resource virtualNetworkLink 'virtualNetworkLinks' = {
    name: '${privateDNSZone.name}-link'
    location: 'global'
    properties: {
      registrationEnabled: false
      virtualNetwork: {
        id: vnet.id
      }
    }
  }
}

// Create a route table
resource routeTable 'Microsoft.Network/routeTables@2024-05-01' = {
  name: routeTableName
  location: location
  tags: tagsUnion
  properties: {
    disableBgpRoutePropagation: false
    routes: [
      // {
      //   id: 'string'
      //   name: 'string'
      //   properties: {
      //     addressPrefix: 'string'
      //     hasBgpOverride: false
      //     nextHopIpAddress: 'string'
      //     nextHopType: 'string'
      //   }
      //   type: 'string'
      // }
    ]
  }
}
