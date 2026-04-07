# Key Vault Module

Creates an Azure Key Vault with RBAC authorization, purge protection, and private-only access by default. Follows enterprise security best practices for secret, key, and certificate management.

## Security Defaults

- **RBAC authorization** — No access policies; permissions are managed via Azure RBAC role assignments
- **Purge protection** — Prevents permanent deletion during soft-delete retention
- **Public access disabled** — Access only through private endpoints by default

## Usage

```hcl
module "key_vault" {
  source              = "../modules/key-vault"
  name                = "kv-foundry-dev-sc"
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"

  tags = {
    environment = "dev"
  }
}
```

## Inputs

| Name                            | Description                                    | Type          | Default      | Required |
|---------------------------------|------------------------------------------------|---------------|--------------|----------|
| `name`                          | The globally unique name of the Key Vault      | `string`      | —            | yes      |
| `resource_group_name`           | The resource group containing this Key Vault   | `string`      | —            | yes      |
| `location`                      | The Azure region                               | `string`      | —            | yes      |
| `tenant_id`                     | The Azure AD tenant ID                         | `string`      | —            | yes      |
| `sku_name`                      | The SKU ('standard' or 'premium')              | `string`      | `"standard"` | no       |
| `public_network_access_enabled` | Enable public access                           | `bool`        | `false`      | no       |
| `tags`                          | Tags to apply                                  | `map(string)` | `{}`         | no       |

## Outputs

| Name        | Description                         |
|-------------|-------------------------------------|
| `id`        | The resource ID of the Key Vault    |
| `vault_uri` | The URI of the Key Vault            |
| `name`      | The name of the Key Vault           |
