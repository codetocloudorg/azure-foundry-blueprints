# Virtual Network Module

Creates an Azure Virtual Network with configurable subnets. Subnets are deployed inline to ensure atomic provisioning and avoid lifecycle issues.

## Resources Deployed

| Resource | Type |
|----------|------|
| Virtual Network | `Microsoft.Network/virtualNetworks` |
| Subnets (inline) | Defined within the VNet resource |

## Parameters

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `name` | `string` | — | The name of the virtual network. |
| `location` | `string` | — | The Azure region for deployment. |
| `addressPrefixes` | `array` | `['10.100.0.0/16']` | Address space CIDR blocks. |
| `subnets` | `array` | `[]` | Subnet definitions (see below). |
| `tags` | `object` | `{}` | Tags to apply. |

### Subnet Object Schema

```
{
  name: string
  addressPrefix: string
  privateEndpointNetworkPolicies?: string  // 'Enabled' (default) or 'Disabled'
}
```

## Outputs

| Name | Type | Description |
|------|------|-------------|
| `id` | `string` | The resource ID of the virtual network. |
| `name` | `string` | The name of the virtual network. |
| `subnetIds` | `object` | Map of subnet name → subnet resource ID. |

## Example Usage

```bicep
module vnet 'modules/vnet/main.bicep' = {
  name: 'vnet-deployment'
  params: {
    name: 'vnet-foundry-dev-eus2-001'
    location: 'eastus2'
    addressPrefixes: ['10.100.0.0/16']
    subnets: [
      {
        name: 'snet-default'
        addressPrefix: '10.100.0.0/24'
      }
      {
        name: 'snet-pe'
        addressPrefix: '10.100.1.0/24'
        privateEndpointNetworkPolicies: 'Disabled'
      }
    ]
    tags: {
      environment: 'dev'
      workload: 'foundry'
    }
  }
}
```
