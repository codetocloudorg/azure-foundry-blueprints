# Log Analytics Workspace Module

Creates a Log Analytics workspace for centralized logging and monitoring. This workspace serves as the data sink for Application Insights and diagnostic settings across all spoke resources.

## Resources Deployed

| Resource | Type |
|----------|------|
| Log Analytics Workspace | `Microsoft.OperationalInsights/workspaces` |

## Parameters

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `name` | `string` | — | The name of the workspace (4–63 chars). |
| `location` | `string` | — | The Azure region for deployment. |
| `sku` | `string` | `'PerGB2018'` | Pricing tier (Free, PerGB2018, PerNode, Premium, Standalone, Standard). |
| `retentionInDays` | `int` | `30` | Log retention period in days (30–730). |
| `tags` | `object` | `{}` | Tags to apply. |

## Outputs

| Name | Type | Description |
|------|------|-------------|
| `id` | `string` | The resource ID of the workspace. |
| `workspaceId` | `string` | The unique workspace ID (GUID). |
| `customerId` | `string` | The customer ID (GUID) of the workspace. |

## Example Usage

```bicep
module logAnalytics 'modules/log-analytics/main.bicep' = {
  name: 'log-analytics-deployment'
  params: {
    name: 'log-foundry-dev-eus2-001'
    location: 'eastus2'
    sku: 'PerGB2018'
    retentionInDays: 90
    tags: {
      environment: 'dev'
      workload: 'foundry'
    }
  }
}
```
