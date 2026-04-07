# Private Endpoint Module

Creates an Azure Private Endpoint for a target resource, routing all traffic over the virtual network. Integrates with Private DNS Zones for FQDN resolution.

## Usage

```hcl
module "pe_keyvault" {
  source              = "../modules/private-endpoint"
  name                = "pe-kv-foundry-dev"
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  subnet_id           = module.vnet.subnet_ids["snet-private-endpoints"]

  private_connection_resource_id = module.key_vault.id
  subresource_names              = ["vault"]
  private_dns_zone_ids           = [module.dns_keyvault.id]

  tags = {
    environment = "dev"
  }
}
```

## Inputs

| Name                              | Description                                          | Type           | Default | Required |
|-----------------------------------|------------------------------------------------------|----------------|---------|----------|
| `name`                            | The name of the private endpoint                     | `string`       | —       | yes      |
| `resource_group_name`             | The resource group containing this endpoint          | `string`       | —       | yes      |
| `location`                        | The Azure region                                     | `string`       | —       | yes      |
| `subnet_id`                       | The subnet where the endpoint NIC is placed          | `string`       | —       | yes      |
| `private_connection_resource_id`  | The resource ID of the target resource               | `string`       | —       | yes      |
| `subresource_names`               | Subresource names (e.g. `["vault"]`, `["blob"]`)     | `list(string)` | —       | yes      |
| `private_dns_zone_ids`            | Private DNS zone IDs for DNS registration            | `list(string)` | —       | yes      |
| `tags`                            | Tags to apply                                        | `map(string)`  | `{}`    | no       |

## Outputs

| Name                 | Description                                    |
|----------------------|------------------------------------------------|
| `id`                 | The resource ID of the private endpoint        |
| `private_ip_address` | The private IP address of the endpoint         |
