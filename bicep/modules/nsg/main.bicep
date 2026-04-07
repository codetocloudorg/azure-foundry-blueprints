// Network Security Group Module
// ------------------------------
// Creates an NSG with enterprise-style default rules (deny inbound internet,
// allow VNet-to-VNet) plus optional custom rules. Subnet association is handled
// by the caller or parent orchestration template to keep this module focused
// on a single responsibility.

// ---------------------
// Parameters
// ---------------------

@description('The name of the network security group.')
@minLength(1)
@maxLength(80)
param name string

@description('The Azure region where the NSG will be created.')
param location string

@description('A list of custom security rules to add beyond the default deny/allow rules.')
param customRules array = []
// Each element: {
//   name: string, priority: int, direction: string, access: string,
//   protocol: string, sourcePortRange: string, destinationPortRange: string,
//   sourceAddressPrefix: string, destinationAddressPrefix: string
// }

@description('A map of tags to apply to the NSG.')
param tags object = {}

// ---------------------
// Variables
// ---------------------

// Default enterprise rules — always present in every NSG.
var defaultRules = [
  {
    name: 'AllowVNetInbound'
    properties: {
      priority: 100
      direction: 'Inbound'
      access: 'Allow'
      protocol: '*'
      sourcePortRange: '*'
      destinationPortRange: '*'
      sourceAddressPrefix: 'VirtualNetwork'
      destinationAddressPrefix: 'VirtualNetwork'
    }
  }
  {
    name: 'DenyInternetInbound'
    properties: {
      priority: 4096
      direction: 'Inbound'
      access: 'Deny'
      protocol: '*'
      sourcePortRange: '*'
      destinationPortRange: '*'
      sourceAddressPrefix: 'Internet'
      destinationAddressPrefix: '*'
    }
  }
]

// Transform caller-supplied custom rules into the ARM security rule format.
var customSecurityRules = [
  for rule in customRules: {
    name: rule.name
    properties: {
      priority: rule.priority
      direction: rule.direction
      access: rule.access
      protocol: rule.protocol
      sourcePortRange: rule.sourcePortRange
      destinationPortRange: rule.destinationPortRange
      sourceAddressPrefix: rule.sourceAddressPrefix
      destinationAddressPrefix: rule.destinationAddressPrefix
    }
  }
]

// Merge default and custom rules into a single array for the NSG.
var allRules = concat(defaultRules, customSecurityRules)

// ---------------------
// Resources
// ---------------------

resource nsg 'Microsoft.Network/networkSecurityGroups@2024-05-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    securityRules: allRules
  }
}

// ---------------------
// Outputs
// ---------------------

@description('The resource ID of the network security group.')
output id string = nsg.id

@description('The name of the network security group.')
output name string = nsg.name
