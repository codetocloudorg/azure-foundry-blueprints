// Virtual Network Module
// ----------------------
// Creates an Azure Virtual Network with configurable subnets.
// Subnets are defined as child resources so downstream modules can
// reference individual subnet IDs without depending on the entire VNet.

// ---------------------
// Parameters
// ---------------------

@description('The name of the virtual network.')
@minLength(2)
@maxLength(64)
param name string

@description('The Azure region where the virtual network will be created.')
param location string

@description('The address space (CIDR blocks) for the virtual network.')
param addressPrefixes array = ['10.100.0.0/16']

@description('A list of subnet definitions to create within the VNet.')
param subnets array = []
// Each element: { name: string, addressPrefix: string, privateEndpointNetworkPolicies?: string }

@description('A map of tags to apply to the virtual network.')
param tags object = {}

// ---------------------
// Resources
// ---------------------

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: addressPrefixes
    }
    // Subnets are defined inline so the VNet and its subnets are deployed
    // atomically, avoiding ordering issues with separate subnet resources.
    subnets: [
      for subnet in subnets: {
        name: subnet.name
        properties: {
          addressPrefix: subnet.addressPrefix
          privateEndpointNetworkPolicies: subnet.?privateEndpointNetworkPolicies ?? 'Enabled'
        }
      }
    ]
  }
}

// ---------------------
// Outputs
// ---------------------

@description('The resource ID of the virtual network.')
output id string = virtualNetwork.id

@description('The name of the virtual network.')
output name string = virtualNetwork.name

@description('A map of subnet names to their resource IDs for downstream lookups.')
output subnetIds object = reduce(
  virtualNetwork.properties.subnets,
  {},
  (acc, subnet) => union(acc, { '${subnet.name}': subnet.id })
)
