# Private DNS Zone Module

Creates a private DNS zone and links it to a virtual network. Private DNS zones enable name resolution for private endpoints, ensuring resources are reachable by FQDN over the private network.

## Resources Deployed

| Resource | Type |
|----------|------|
| Private DNS Zone | `Microsoft.Network/privateDnsZones` |
| Virtual Network Link | `Microsoft.Network/privateDnsZones/virtualNetworkLinks` |

## Parameters

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `name` | `string` | — | The DNS zone name (e.g. `privatelink.vaultcore.azure.net`). |
| `virtualNetworkId` | `string` | — | Resource ID of the VNet to link to. |
| `tags` | `object` | `{}` | Tags to apply. |

## Outputs

| Name | Type | Description |
|------|------|-------------|
| `id` | `string` | The resource ID of the private DNS zone. |
| `name` | `string` | The name of the private DNS zone. |

## Example Usage

```bicep
module privateDns 'modules/private-dns/main.bicep' = {
  name: 'private-dns-keyvault'
  params: {
    name: 'privatelink.vaultcore.azure.net'
    virtualNetworkId: vnet.outputs.id
    tags: {
      environment: 'dev'
      workload: 'foundry'
    }
  }
}
```
