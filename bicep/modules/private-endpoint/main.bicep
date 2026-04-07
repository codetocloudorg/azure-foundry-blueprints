// Private Endpoint Module
// -----------------------
// Creates a private endpoint for a target Azure resource, routing traffic
// over the VNet instead of the public internet. Integrates with private
// DNS zones to enable FQDN-based resolution of the private IP.

// ---------------------
// Parameters
// ---------------------

@description('The name of the private endpoint.')
@minLength(2)
@maxLength(64)
param name string

@description('The Azure region where the private endpoint will be created.')
param location string

@description('The resource ID of the subnet where the private endpoint NIC will be placed.')
param subnetId string

@description('The resource ID of the target Azure resource to connect to privately.')
param privateLinkServiceId string

@description('The subresource (group) names on the target resource (e.g. ["vault"], ["blob"]).')
param groupIds array

@description('A list of private DNS zone IDs to register the endpoint\'s IP address in.')
param privateDnsZoneIds array

@description('A map of tags to apply to the private endpoint.')
param tags object = {}

// ---------------------
// Resources
// ---------------------

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2024-05-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    subnet: {
      id: subnetId
    }
    // The service connection links this endpoint to a specific subresource
    // on the target resource (e.g. "vault" for Key Vault, "blob" for Storage).
    privateLinkServiceConnections: [
      {
        name: '${name}-connection'
        properties: {
          privateLinkServiceId: privateLinkServiceId
          groupIds: groupIds
        }
      }
    ]
  }
}

// Register the private endpoint IP in the supplied private DNS zone(s)
// so that the resource FQDN resolves to the private IP within the VNet.
resource dnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2024-05-01' = {
  parent: privateEndpoint
  name: '${name}-dns-zone-group'
  properties: {
    privateDnsZoneConfigs: [
      for (zoneId, i) in privateDnsZoneIds: {
        name: 'config-${i}'
        properties: {
          privateDnsZoneId: zoneId
        }
      }
    ]
  }
}

// ---------------------
// Outputs
// ---------------------

@description('The resource ID of the private endpoint.')
output id string = privateEndpoint.id
