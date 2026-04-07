# Private DNS Zone Module

Creates an Azure Private DNS Zone and links it to a Virtual Network. This enables private name resolution for services accessed through private endpoints.

## Usage

```hcl
module "dns_keyvault" {
  source              = "../modules/private-dns"
  name                = "privatelink.vaultcore.azure.net"
  resource_group_name = module.resource_group.name
  virtual_network_id  = module.vnet.id

  tags = {
    environment = "dev"
  }
}
```

## Common Private DNS Zone Names

| Service              | DNS Zone Name                                  |
|----------------------|------------------------------------------------|
| Key Vault            | `privatelink.vaultcore.azure.net`              |
| Storage (Blob)       | `privatelink.blob.core.windows.net`            |
| Cognitive Services   | `privatelink.cognitiveservices.azure.com`       |
| AI Services          | `privatelink.services.ai.azure.com`            |

## Inputs

| Name                  | Description                                    | Type          | Default | Required |
|-----------------------|------------------------------------------------|---------------|---------|----------|
| `name`                | The private DNS zone name                      | `string`      | —       | yes      |
| `resource_group_name` | The resource group containing this zone        | `string`      | —       | yes      |
| `virtual_network_id`  | The VNet ID to link this zone to               | `string`      | —       | yes      |
| `tags`                | Tags to apply                                  | `map(string)` | `{}`    | no       |

## Outputs

| Name   | Description                           |
|--------|---------------------------------------|
| `id`   | The resource ID of the DNS zone       |
| `name` | The name of the DNS zone              |
