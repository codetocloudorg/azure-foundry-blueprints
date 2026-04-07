# Log Analytics Module

Creates an Azure Log Analytics workspace for centralized logging, monitoring, and diagnostics. This workspace backs Application Insights and receives diagnostic data from all resources in the spoke.

## Usage

```hcl
module "log_analytics" {
  source              = "../modules/log-analytics"
  name                = "log-foundry-dev-swedencentral"
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  sku                 = "PerGB2018"
  retention_in_days   = 30

  tags = {
    environment = "dev"
  }
}
```

## Inputs

| Name                  | Description                              | Type          | Default       | Required |
|-----------------------|------------------------------------------|---------------|---------------|----------|
| `name`                | The name of the workspace                | `string`      | —             | yes      |
| `resource_group_name` | The resource group containing this workspace | `string`  | —             | yes      |
| `location`            | The Azure region                         | `string`      | —             | yes      |
| `sku`                 | The pricing tier                         | `string`      | `"PerGB2018"` | no       |
| `retention_in_days`   | Days to retain log data (30–730)         | `number`      | `30`          | no       |
| `tags`                | Tags to apply                            | `map(string)` | `{}`          | no       |

## Outputs

| Name                 | Description                                          |
|----------------------|------------------------------------------------------|
| `id`                 | The resource ID of the workspace                     |
| `workspace_id`       | The unique workspace ID (GUID)                       |
| `primary_shared_key` | The primary shared key (sensitive)                   |
