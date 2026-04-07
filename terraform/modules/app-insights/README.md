# Application Insights Module

Creates a workspace-based Azure Application Insights instance for application performance monitoring and telemetry. Requires a Log Analytics workspace as a backend.

## Usage

```hcl
module "app_insights" {
  source              = "../modules/app-insights"
  name                = "appi-foundry-dev-swedencentral"
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  application_type    = "web"
  workspace_id        = module.log_analytics.id

  tags = {
    environment = "dev"
  }
}
```

## Inputs

| Name                  | Description                                     | Type          | Default  | Required |
|-----------------------|-------------------------------------------------|---------------|----------|----------|
| `name`                | The name of the Application Insights resource   | `string`      | —        | yes      |
| `resource_group_name` | The resource group containing this resource     | `string`      | —        | yes      |
| `location`            | The Azure region                                | `string`      | —        | yes      |
| `application_type`    | The type of application being monitored         | `string`      | `"web"`  | no       |
| `workspace_id`        | The Log Analytics workspace resource ID         | `string`      | —        | yes      |
| `tags`                | Tags to apply                                   | `map(string)` | `{}`     | no       |

## Outputs

| Name                  | Description                                    |
|-----------------------|------------------------------------------------|
| `id`                  | The resource ID of Application Insights        |
| `instrumentation_key` | The instrumentation key (sensitive)            |
| `connection_string`   | The connection string (sensitive)              |
