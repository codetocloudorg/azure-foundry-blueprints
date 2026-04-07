# Application Insights Module

Creates an Application Insights instance backed by a Log Analytics workspace. Uses the workspace-based (v2) mode — classic mode is deprecated.

## Resources Deployed

| Resource | Type |
|----------|------|
| Application Insights | `Microsoft.Insights/components` |

## Parameters

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `name` | `string` | — | The name of the Application Insights resource. |
| `location` | `string` | — | The Azure region for deployment. |
| `applicationType` | `string` | `'web'` | Application type: `web`, `java`, or `other`. |
| `workspaceId` | `string` | — | Resource ID of the backing Log Analytics workspace. |
| `tags` | `object` | `{}` | Tags to apply. |

## Outputs

| Name | Type | Description |
|------|------|-------------|
| `id` | `string` | The resource ID of the Application Insights instance. |
| `instrumentationKey` | `string` | Instrumentation key for telemetry producers. |
| `connectionString` | `string` | Connection string for Application Insights. |

## Example Usage

```bicep
module appInsights 'modules/app-insights/main.bicep' = {
  name: 'app-insights-deployment'
  params: {
    name: 'appi-foundry-dev-eus2-001'
    location: 'eastus2'
    applicationType: 'web'
    workspaceId: logAnalytics.outputs.id
    tags: {
      environment: 'dev'
      workload: 'foundry'
    }
  }
}
```
