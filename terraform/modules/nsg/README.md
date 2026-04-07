# Network Security Group Module

Creates an Azure Network Security Group with enterprise-style default rules and optional custom rules, then associates it with a subnet.

## Default Rules

| Rule                  | Priority | Direction | Access | Description                          |
|-----------------------|----------|-----------|--------|--------------------------------------|
| `AllowVNetInbound`    | 100      | Inbound   | Allow  | Allow traffic within the VNet        |
| `DenyInternetInbound` | 4096     | Inbound   | Deny   | Deny all inbound internet traffic    |

## Usage

```hcl
module "nsg" {
  source              = "../modules/nsg"
  name                = "nsg-private-endpoints"
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  subnet_id           = module.vnet.subnet_ids["snet-private-endpoints"]

  custom_rules = [
    {
      name                       = "AllowHttpsInbound"
      priority                   = 200
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "443"
      source_address_prefix      = "VirtualNetwork"
      destination_address_prefix = "VirtualNetwork"
    }
  ]

  tags = {
    environment = "dev"
  }
}
```

## Inputs

| Name                  | Description                                  | Type           | Default | Required |
|-----------------------|----------------------------------------------|----------------|---------|----------|
| `name`                | The name of the NSG                          | `string`       | —       | yes      |
| `resource_group_name` | The resource group containing this NSG       | `string`       | —       | yes      |
| `location`            | The Azure region for the NSG                 | `string`       | —       | yes      |
| `subnet_id`           | The ID of the subnet to associate with       | `string`       | —       | yes      |
| `custom_rules`        | List of custom security rule objects         | `list(object)` | `[]`    | no       |
| `tags`                | Tags to apply                                | `map(string)`  | `{}`    | no       |

## Outputs

| Name   | Description                     |
|--------|---------------------------------|
| `id`   | The ID of the NSG               |
| `name` | The name of the NSG             |
