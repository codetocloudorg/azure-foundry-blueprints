# Virtual Network Module

Creates an Azure Virtual Network with configurable subnets. Subnets are created as separate resources to allow individual referencing by downstream modules.

## Usage

```hcl
module "vnet" {
  source              = "../modules/vnet"
  name                = "vnet-foundry-dev-swedencentral"
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location

  address_space = ["10.100.0.0/16"]

  subnets = [
    {
      name                              = "snet-private-endpoints"
      address_prefixes                  = ["10.100.1.0/24"]
      private_endpoint_network_policies = "Disabled"
    },
    {
      name                              = "snet-workloads"
      address_prefixes                  = ["10.100.2.0/24"]
      private_endpoint_network_policies = "Enabled"
    }
  ]

  tags = {
    environment = "dev"
  }
}
```

## Inputs

| Name                  | Description                                      | Type           | Default            | Required |
|-----------------------|--------------------------------------------------|----------------|--------------------|----------|
| `name`                | The name of the virtual network                  | `string`       | —                  | yes      |
| `resource_group_name` | The resource group that contains this VNet        | `string`       | —                  | yes      |
| `location`            | The Azure region for the VNet                    | `string`       | —                  | yes      |
| `address_space`       | CIDR blocks for the VNet                         | `list(string)` | `["10.100.0.0/16"]`| no       |
| `subnets`             | List of subnet objects to create                 | `list(object)` | `[]`               | no       |
| `tags`                | Tags to apply                                    | `map(string)`  | `{}`               | no       |

### Subnet Object

| Field                              | Description                              | Type           | Default     |
|-------------------------------------|------------------------------------------|----------------|-------------|
| `name`                              | Subnet name                              | `string`       | —           |
| `address_prefixes`                  | CIDR blocks for the subnet               | `list(string)` | —           |
| `private_endpoint_network_policies` | Network policies for private endpoints   | `string`       | `"Enabled"` |

## Outputs

| Name         | Description                                  |
|--------------|----------------------------------------------|
| `id`         | The ID of the virtual network                |
| `name`       | The name of the virtual network              |
| `subnet_ids` | Map of subnet names to their resource IDs    |
