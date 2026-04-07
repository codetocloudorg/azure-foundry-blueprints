# Azure AI Foundry Module

Creates an Azure AI Foundry hub and project using the modern `azurerm_ai_foundry` and `azurerm_ai_foundry_project` resources (azurerm >= 4.x).

The **hub** is the top-level workspace holding shared configuration (Key Vault, Storage, Application Insights, networking). **Projects** are child workspaces scoped to a team or use case.

## Usage

```hcl
module "foundry" {
  source              = "../modules/foundry"
  hub_name            = "aih-foundry-dev-swedencentral"
  project_name        = "aip-foundry-dev-swedencentral"
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  key_vault_id            = module.key_vault.id
  storage_account_id      = module.storage.id
  application_insights_id = module.app_insights.id
  identity_ids            = [module.identity.id]

  public_network_access = "Disabled"

  tags = {
    environment = "dev"
  }
}
```

## Inputs

| Name                      | Description                                          | Type           | Default      | Required |
|---------------------------|------------------------------------------------------|----------------|--------------|----------|
| `hub_name`                | The name of the Foundry hub                          | `string`       | —            | yes      |
| `project_name`            | The name of the Foundry project                      | `string`       | —            | yes      |
| `resource_group_name`     | The resource group containing these resources        | `string`       | —            | yes      |
| `location`                | The Azure region                                     | `string`       | —            | yes      |
| `key_vault_id`            | The Key Vault resource ID                            | `string`       | —            | yes      |
| `storage_account_id`      | The Storage Account resource ID                      | `string`       | —            | yes      |
| `application_insights_id` | The Application Insights resource ID                 | `string`       | —            | yes      |
| `identity_ids`            | User-assigned managed identity IDs                   | `list(string)` | —            | yes      |
| `public_network_access`   | Public access ('Enabled' or 'Disabled')              | `string`       | `"Disabled"` | no       |
| `tags`                    | Tags to apply                                        | `map(string)`  | `{}`         | no       |

## Outputs

| Name           | Description                               |
|----------------|-------------------------------------------|
| `hub_id`       | The resource ID of the Foundry hub        |
| `project_id`   | The resource ID of the Foundry project    |
| `hub_endpoint` | The discovery URL of the Foundry hub      |
