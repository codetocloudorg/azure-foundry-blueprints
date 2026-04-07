# Key Vault Module

Creates an Azure Key Vault with RBAC-based authorization, purge protection, and public network access disabled by default. Follows enterprise security best practices for secret management.

## Resources Deployed

| Resource | Type |
|----------|------|
| Key Vault | `Microsoft.KeyVault/vaults` |

## Security Features

- **RBAC authorization** — uses Azure RBAC instead of vault access policies
- **Purge protection** — prevents permanent deletion during soft-delete retention
- **Soft delete** — enabled by default
- **Private-only access** — public network access disabled by default

## Parameters

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `name` | `string` | — | Globally unique Key Vault name (3–24 chars). |
| `location` | `string` | — | The Azure region for deployment. |
| `tenantId` | `string` | — | Azure AD tenant ID. |
| `skuName` | `string` | `'standard'` | SKU: `standard` or `premium`. |
| `publicNetworkAccess` | `string` | `'Disabled'` | `Enabled` or `Disabled`. |
| `tags` | `object` | `{}` | Tags to apply. |

## Outputs

| Name | Type | Description |
|------|------|-------------|
| `id` | `string` | The resource ID of the Key Vault. |
| `vaultUri` | `string` | The vault URI (e.g. `https://<name>.vault.azure.net/`). |
| `kvName` | `string` | The name of the Key Vault. |

## Example Usage

```bicep
module keyVault 'modules/key-vault/main.bicep' = {
  name: 'key-vault-deployment'
  params: {
    name: 'kv-foundry-dev-eus2-001'
    location: 'eastus2'
    tenantId: subscription().tenantId
    skuName: 'standard'
    publicNetworkAccess: 'Disabled'
    tags: {
      environment: 'dev'
      workload: 'foundry'
    }
  }
}
```
