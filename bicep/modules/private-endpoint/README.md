# Private Endpoint Module

Creates a private endpoint for a target Azure resource, routing traffic over the VNet instead of the public internet. Automatically registers the endpoint IP in private DNS zones for FQDN-based resolution.

## Resources Deployed

| Resource | Type |
|----------|------|
| Private Endpoint | `Microsoft.Network/privateEndpoints` |
| DNS Zone Group | `Microsoft.Network/privateEndpoints/privateDnsZoneGroups` |

## Parameters

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `name` | `string` | — | The name of the private endpoint. |
| `location` | `string` | — | The Azure region for deployment. |
| `subnetId` | `string` | — | Subnet ID for the private endpoint NIC. |
| `privateLinkServiceId` | `string` | — | Resource ID of the target resource. |
| `groupIds` | `array` | — | Subresource names (e.g. `['vault']`, `['blob']`). |
| `privateDnsZoneIds` | `array` | — | Private DNS zone IDs for IP registration. |
| `tags` | `object` | `{}` | Tags to apply. |

## Outputs

| Name | Type | Description |
|------|------|-------------|
| `id` | `string` | The resource ID of the private endpoint. |

## Example Usage

```bicep
module kvEndpoint 'modules/private-endpoint/main.bicep' = {
  name: 'pe-keyvault'
  params: {
    name: 'pep-kv-foundry-dev-eus2-001'
    location: 'eastus2'
    subnetId: vnet.outputs.subnetIds['snet-pe']
    privateLinkServiceId: keyVault.outputs.id
    groupIds: ['vault']
    privateDnsZoneIds: [privateDnsKv.outputs.id]
    tags: {
      environment: 'dev'
      workload: 'foundry'
    }
  }
}
```
