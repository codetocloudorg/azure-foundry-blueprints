# Network Security Group Module

Creates an Azure Network Security Group with enterprise-style default rules and optional custom rules. Default rules deny all inbound internet traffic and allow VNet-to-VNet communication.

## Resources Deployed

| Resource | Type |
|----------|------|
| Network Security Group | `Microsoft.Network/networkSecurityGroups` |

## Default Security Rules

| Rule Name | Priority | Direction | Access | Source | Destination |
|-----------|----------|-----------|--------|--------|-------------|
| AllowVNetInbound | 100 | Inbound | Allow | VirtualNetwork | VirtualNetwork |
| DenyInternetInbound | 4096 | Inbound | Deny | Internet | * |

## Parameters

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `name` | `string` | — | The name of the NSG. |
| `location` | `string` | — | The Azure region for deployment. |
| `customRules` | `array` | `[]` | Custom security rules (see below). |
| `tags` | `object` | `{}` | Tags to apply. |

> **Note:** Subnet association is handled by the caller (e.g. parent orchestration template) to keep this module single-responsibility.

### Custom Rule Object Schema

```
{
  name: string
  priority: int            // 100–4096
  direction: string        // 'Inbound' or 'Outbound'
  access: string           // 'Allow' or 'Deny'
  protocol: string         // 'Tcp', 'Udp', 'Icmp', or '*'
  sourcePortRange: string
  destinationPortRange: string
  sourceAddressPrefix: string
  destinationAddressPrefix: string
}
```

## Outputs

| Name | Type | Description |
|------|------|-------------|
| `id` | `string` | The resource ID of the NSG. |
| `name` | `string` | The name of the NSG. |

## Example Usage

```bicep
module nsg 'modules/nsg/main.bicep' = {
  name: 'nsg-deployment'
  params: {
    name: 'nsg-foundry-dev-eus2-001'
    location: 'eastus2'
    customRules: [
      {
        name: 'AllowHTTPS'
        priority: 200
        direction: 'Inbound'
        access: 'Allow'
        protocol: 'Tcp'
        sourcePortRange: '*'
        destinationPortRange: '443'
        sourceAddressPrefix: 'VirtualNetwork'
        destinationAddressPrefix: 'VirtualNetwork'
      }
    ]
    tags: {
      environment: 'dev'
      workload: 'foundry'
    }
  }
}
```
