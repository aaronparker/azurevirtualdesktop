// Target the resource group to deploy network resources into
targetScope = 'resourceGroup'

@description('The region or location the network resources will be deployed into.')
var location = resourceGroup().location

@description('The date and time the resources are being deployed.')
param date string = utcNow('yyyy-MM-dd HH:mm:ss')

@description('Enter your email address. This will be included in the Owner tag on the target resources.')
param email string

@description('Whether to deploy a NAT gateway for the virtual network. Default is true.')
param deployNatGateway bool

@description('Tags to be applied to all resources created by this template.')
param tags object = {
  Application: 'Azure Virtual Desktop'
  Criticality: 'Medium'
  Environment: 'Demo'
  Function: 'Azure Virtual Desktop session host network.'
  LastUpdateBy: email
  LastUpdateDate: date
  Type: 'Network'
}

@description('The name of the service being deployed, used for abbreviations in resource names.')
@maxLength(4)
@minLength(2)
param service string = 'Avd'

@description('Abbreviations for resource names to keep them short and within Azure limits.')
param abbr object = {
  service: service
  appGroup: 'vdag'
  availSet: 'avail'
  computeGallery: 'gal'
  hostPool: 'vdpool'
  identity: 'id'
  imgTemplate: 'it'
  keyVault: 'kv'
  logAnalytics: 'log'
  natGateway: 'ng'
  network: 'vnet'
  networkManager: 'vnm'
  nsg: 'nsg'
  privateEndpoint: 'pep'
  privateLink: 'pl'
  publicIp: 'pip'
  resourceGroup: 'rg'
  routeTable: 'rt'
  scalingPlan: 'vdscaling'
  storage: 'stavd'
  subnet: 'snet'
  userRoute: 'udr'
  workspace: 'vdws'
}

@description('The name of the service being deployed (e.g. HostPools, Windows365, Servers). This will be used for resource names.')
param name string = 'HostPools'

@description('The address space for the virtual network.')
param addressSpace string = '10.0.0.0/16'

@description('The subnets to be created in the virtual network.')
param subnets array = [
  {
    name: 'GatewaySubnet'
    subnetPrefix: '10.0.0.0/27'
    privateLinkService: 'Disabled'
  }
  {
    name: 'Storage'
    subnetPrefix: '10.1.0.0/24'
    privateLinkService: 'Enabled'
  }
  {
    name: 'Images'
    subnetPrefix: '10.2.0.0/23'
    privateLinkService: 'Disabled'
  }
  {
    name: 'Management'
    subnetPrefix: '10.4.0.0/23'
    privateLinkService: 'Enabled'
  }
  {
    name: 'Desktops1'
    subnetPrefix: '10.6.0.0/23'
    privateLinkService: 'Enabled'
  }
  {
    name: 'Desktops2'
    subnetPrefix: '10.8.0.0/23'
    privateLinkService: 'Enabled'
  }
  {
    name: 'Desktops3'
    subnetPrefix: '10.10.0.0/23'
    privateLinkService: 'Enabled'
  }
  {
    name: 'Desktops4'
    subnetPrefix: '10.12.0.0/23'
    privateLinkService: 'Enabled'
  }
]

@description('Network security group rules to be applied to the NSG. Includes default outbound block rules for security.')
param nsgRules array = [
  {
    name: 'AllowImageProxyInbound'
    properties: {
      access: 'Allow'
      description: 'Allow Image Builder Private Link Access to Proxy VM'
      destinationAddressPrefix: 'VirtualNetwork'
      destinationAddressPrefixes: []
      destinationPortRange: '60000-60001'
      destinationPortRanges: []
      direction: 'Inbound'
      priority: 100
      protocol: 'TCP'
      sourceAddressPrefix: 'AzureLoadBalancer'
      sourceAddressPrefixes: []
      sourcePortRange: '*'
      sourcePortRanges: []
    }
  }
  {
    name: 'DenyAnySMTPOutbound'
    properties: {
      access: 'Deny'
      description: 'Deny any SMTP outbound to the internet'
      destinationAddressPrefix: 'Internet'
      destinationAddressPrefixes: []
      destinationPortRange: '25'
      destinationPortRanges: []
      direction: 'Outbound'
      priority: 100
      protocol: 'TCP'
      sourceAddressPrefix: '*'
      sourceAddressPrefixes: []
      sourcePortRange: '*'
      sourcePortRanges: []
    }
  }
  {
    name: 'DenyAnySMTPSOutbound'
    properties: {
      access: 'Deny'
      description: 'Deny any SMTPS outbound to the internet'
      destinationAddressPrefix: 'Internet'
      destinationAddressPrefixes: []
      destinationPortRange: '465'
      destinationPortRanges: []
      direction: 'Outbound'
      priority: 110
      protocol: 'TCP'
      sourceAddressPrefix: '*'
      sourceAddressPrefixes: []
      sourcePortRange: '*'
      sourcePortRanges: []
    }
  }
  {
    name: 'DenyAnyPOP3Outbound'
    properties: {
      access: 'Deny'
      description: 'Deny any POP3 outbound to the internet'
      destinationAddressPrefix: 'Internet'
      destinationAddressPrefixes: []
      destinationPortRange: '110'
      destinationPortRanges: []
      direction: 'Outbound'
      priority: 120
      protocol: 'TCP'
      sourceAddressPrefix: '*'
      sourceAddressPrefixes: []
      sourcePortRange: '*'
      sourcePortRanges: []
    }
  }
  {
    name: 'DenyAnyPOP3SOutbound'
    properties: {
      access: 'Deny'
      description: 'Deny any POP3S outbound to the internet'
      destinationAddressPrefix: 'Internet'
      destinationAddressPrefixes: []
      destinationPortRange: '995'
      destinationPortRanges: []
      direction: 'Outbound'
      priority: 130
      protocol: 'TCP'
      sourceAddressPrefix: '*'
      sourceAddressPrefixes: []
      sourcePortRange: '*'
      sourcePortRanges: []
    }
  }
  {
    name: 'DenyAnyIMAPOutbound'
    properties: {
      access: 'Deny'
      description: 'Deny any IMAP outbound to the internet'
      destinationAddressPrefix: 'Internet'
      destinationAddressPrefixes: []
      destinationPortRange: '143'
      destinationPortRanges: []
      direction: 'Outbound'
      priority: 140
      protocol: 'TCP'
      sourceAddressPrefix: '*'
      sourceAddressPrefixes: []
      sourcePortRange: '*'
      sourcePortRanges: []
    }
  }
  {
    name: 'DenyAnyIMAPSOutbound'
    properties: {
      access: 'Deny'
      description: 'Deny any IMAPS outbound to the internet'
      destinationAddressPrefix: 'Internet'
      destinationAddressPrefixes: []
      destinationPortRange: '993'
      destinationPortRanges: []
      direction: 'Outbound'
      priority: 150
      protocol: 'TCP'
      sourceAddressPrefix: '*'
      sourceAddressPrefixes: []
      sourcePortRange: '*'
      sourcePortRanges: []
    }
  }
  {
    name: 'DenyAnySMBOutbound'
    properties: {
      access: 'Deny'
      description: 'Deny any SMB outbound to the internet'
      destinationAddressPrefix: 'Internet'
      destinationAddressPrefixes: []
      destinationPortRange: '445'
      destinationPortRanges: []
      direction: 'Outbound'
      priority: 160
      protocol: 'TCP'
      sourceAddressPrefix: '*'
      sourceAddressPrefixes: []
      sourcePortRange: '*'
      sourcePortRanges: []
    }
  }
  {
    name: 'DenyAnyNetBIOSNameResolutionOutbound'
    properties: {
      access: 'Deny'
      description: 'Deny any NetBIOS name resolution outbound to the internet'
      destinationAddressPrefix: 'Internet'
      destinationAddressPrefixes: []
      destinationPortRange: '137'
      destinationPortRanges: []
      direction: 'Outbound'
      priority: 170
      protocol: 'UDP'
      sourceAddressPrefix: '*'
      sourceAddressPrefixes: []
      sourcePortRange: '*'
      sourcePortRanges: []
    }
  }
  {
    name: 'DenyAnyNetBIOSDatagramOutbound'
    properties: {
      access: 'Deny'
      description: 'Deny any NetBIOS datagram service outbound to the internet'
      destinationAddressPrefix: 'Internet'
      destinationAddressPrefixes: []
      destinationPortRange: '138'
      destinationPortRanges: []
      direction: 'Outbound'
      priority: 180
      protocol: 'UDP'
      sourceAddressPrefix: '*'
      sourceAddressPrefixes: []
      sourcePortRange: '*'
      sourcePortRanges: []
    }
  }
  {
    name: 'DenyAnyNetBIOSSessionOutbound'
    properties: {
      access: 'Deny'
      description: 'Deny any NetBIOS session service outbound to the internet'
      destinationAddressPrefix: 'Internet'
      destinationAddressPrefixes: []
      destinationPortRange: '139'
      destinationPortRanges: []
      direction: 'Outbound'
      priority: 190
      protocol: 'TCP'
      sourceAddressPrefix: '*'
      sourceAddressPrefixes: []
      sourcePortRange: '*'
      sourcePortRanges: []
    }
  }
  {
    name: 'DenyAnyTFTPOutbound'
    properties: {
      access: 'Deny'
      description: 'Deny any Trivial File Transfer Protocol outbound to the internet'
      destinationAddressPrefix: 'Internet'
      destinationAddressPrefixes: []
      destinationPortRange: '69'
      destinationPortRanges: []
      direction: 'Outbound'
      priority: 200
      protocol: 'UDP'
      sourceAddressPrefix: '*'
      sourceAddressPrefixes: []
      sourcePortRange: '*'
      sourcePortRanges: []
    }
  }
  {
    name: 'DenyAnySysLogOutbound'
    properties: {
      access: 'Deny'
      description: 'Deny any System Log outbound to the internet'
      destinationAddressPrefix: 'Internet'
      destinationAddressPrefixes: []
      destinationPortRange: '514'
      destinationPortRanges: []
      direction: 'Outbound'
      priority: 210
      protocol: 'UDP'
      sourceAddressPrefix: '*'
      sourceAddressPrefixes: []
      sourcePortRange: '*'
      sourcePortRanges: []
    }
  }
  {
    name: 'DenyAnySNMPOutbound'
    properties: {
      access: 'Deny'
      description: 'Deny any Simple Network Management Protocol outbound to the internet'
      destinationAddressPrefix: 'Internet'
      destinationAddressPrefixes: []
      destinationPortRange: '161-162'
      destinationPortRanges: []
      direction: 'Outbound'
      priority: 220
      protocol: 'UDP'
      sourceAddressPrefix: '*'
      sourceAddressPrefixes: []
      sourcePortRange: '*'
      sourcePortRanges: []
    }
  }
  {
    name: 'DenyAnyIRCOutbound'
    properties: {
      access: 'Deny'
      description: 'Deny any Internet Relay Chat outbound to the internet'
      destinationAddressPrefix: 'Internet'
      destinationAddressPrefixes: []
      destinationPortRange: '6660-6669'
      destinationPortRanges: []
      direction: 'Outbound'
      priority: 230
      protocol: 'TCP'
      sourceAddressPrefix: '*'
      sourceAddressPrefixes: []
      sourcePortRange: '*'
      sourcePortRanges: []
    }
  }
  {
    name: 'DenyAnyWinRMOutbound'
    properties: {
      access: 'Deny'
      description: 'Deny any WinRM outbound to the internet'
      destinationAddressPrefix: 'Internet'
      destinationAddressPrefixes: []
      destinationPortRange: '5986'
      destinationPortRanges: []
      direction: 'Outbound'
      priority: 240
      protocol: 'TCP'
      sourceAddressPrefix: '*'
      sourceAddressPrefixes: []
      sourcePortRange: '*'
      sourcePortRanges: []
    }
  }
]

@description('DNS servers to be used in the virtual network. Default is empty array which uses Azure-provided DNS.')
param dnsServers array = []

// Build a variable for NSG security rules
@description('Build the array of security rules from nsgRules.')
var securityRuleArray = [
  for (securityRule, i) in nsgRules: {
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
      priority: 100 + (10 * i)
      protocol: securityRule.properties.protocol
      sourceAddressPrefix: securityRule.properties.?sourceAddressPrefix ?? ''
      sourceAddressPrefixes: securityRule.properties.?sourceAddressPrefixes ?? []
      sourceApplicationSecurityGroups: securityRule.properties.?sourceApplicationSecurityGroups ?? []
      sourcePortRange: securityRule.properties.?sourcePortRange ?? ''
      sourcePortRanges: securityRule.properties.?sourcePortRanges ?? []
    }
  }
]

@description('An array of service endpoints to create.')
var serviceEndpoints = [
  {
    service: 'Microsoft.Storage'
    locations: [location]
  }
  {
    service: 'Microsoft.KeyVault'
    locations: [location]
  }
]

@description('The private DNS zone name.')
var privateDNSZoneName = 'privatelink.file.${environment().suffixes.storage}'

// Create a network security group to apply to all subnets
resource nsg 'Microsoft.Network/networkSecurityGroups@2024-05-01' = {
  name: '${abbr.nsg}-${abbr.service}-${name}-${location}'
  location: location
  tags: tags
  properties: {
    securityRules: securityRuleArray
  }
}

// Create a public IP for the NAT gateway
resource publicIp 'Microsoft.Network/publicIPAddresses@2024-05-01' = if (deployNatGateway) {
  name: '${abbr.publicIp}-${abbr.service}-${name}-${location}-01'
  location: location
  tags: tags
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
resource natGateway 'Microsoft.Network/natGateways@2024-05-01' = if (deployNatGateway) {
  name: '${abbr.natGateway}-${abbr.service}-${name}-${location}-01'
  location: location
  tags: tags
  sku: {
    name: 'Standard'
  }
  properties: {
    idleTimeoutInMinutes: 4
    publicIpAddresses: [
      {
        id: publicIp.id
      }
    ]
  }
}

// Create the virtual network and subnets, assigning the NSG to all subnets, and assign the NAT gateway
resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: '${abbr.network}-${abbr.service}-${name}-${location}'
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressSpace
      ]
    }
    dhcpOptions: {
      dnsServers: ((!empty(dnsServers)) ? dnsServers : null)
    }
    subnets: [
      for subnet in subnets: {
        name: subnet.name
        properties: {
          addressPrefix: subnet.subnetPrefix
          networkSecurityGroup: {
            id: nsg.id
          }
          natGateway: ((deployNatGateway) ? { id: natGateway.id } : null)
          defaultOutboundAccess: ((deployNatGateway) ? true : false)
          serviceEndpoints: serviceEndpoints
          delegations: []
          //privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: subnet.privateLinkService
        }
      }
    ]
    virtualNetworkPeerings: []
    enableDdosProtection: false
  }
}

// Create the private DNS zone required for private endpoints
resource privateDNSZone 'Microsoft.Network/privateDnsZones@2024-06-01' = {
  name: privateDNSZoneName
  location: 'global'
  tags: tags

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
  name: '${abbr.routeTable}-${abbr.service}-${name}-${location}-01'
  location: location
  tags: tags
  properties: {
    disableBgpRoutePropagation: false
    routes: []
  }
}
