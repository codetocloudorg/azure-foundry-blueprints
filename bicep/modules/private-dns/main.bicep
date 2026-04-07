// Private DNS Zone Module
// -----------------------
// Creates a private DNS zone and links it to a virtual network.
// Private DNS zones enable name resolution for private endpoints,
// ensuring resources are reachable by FQDN over the private network
// without exposing traffic to the public internet.

// ---------------------
// Parameters
// ---------------------

@description('The name of the private DNS zone (e.g. "privatelink.vaultcore.azure.net").')
param name string

@description('The resource ID of the virtual network to link this DNS zone to.')
param virtualNetworkId string

@description('A map of tags to apply to the DNS zone.')
param tags object = {}

// ---------------------
// Resources
// ---------------------

// Private DNS zones are global resources; location is always 'global'.
resource privateDnsZone 'Microsoft.Network/privateDnsZones@2024-06-01' = {
  name: name
  location: 'global'
  tags: tags
}

// Link the DNS zone to the VNet so that resources within the VNet
// can resolve records in this private zone automatically.
resource vnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2024-06-01' = {
  parent: privateDnsZone
  name: '${name}-vnet-link'
  location: 'global'
  properties: {
    virtualNetwork: {
      id: virtualNetworkId
    }
    registrationEnabled: false
  }
}

// ---------------------
// Outputs
// ---------------------

@description('The resource ID of the private DNS zone.')
output id string = privateDnsZone.id

@description('The name of the private DNS zone.')
output name string = privateDnsZone.name
