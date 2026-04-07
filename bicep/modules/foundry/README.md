# Azure AI Foundry Module

Creates an Azure AI Foundry hub and project using the `Microsoft.MachineLearningServices/workspaces` resource type. The hub aggregates shared resources (Key Vault, Storage, App Insights); the project provides team or workload isolation.

## Resources Deployed

| Resource | Type | Kind |
|----------|------|------|
| AI Foundry Hub | `Microsoft.MachineLearningServices/workspaces` | `Hub` |
| AI Foundry Project | `Microsoft.MachineLearningServices/workspaces` | `Project` |

## Parameters

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `hubName` | `string` | — | Name of the AI Foundry hub (2–33 chars). |
| `projectName` | `string` | — | Name of the AI Foundry project (2–33 chars). |
| `location` | `string` | — | The Azure region for deployment. |
| `skuName` | `string` | `'Basic'` | SKU: `Basic` or `Standard`. |
| `keyVaultId` | `string` | — | Resource ID of the associated Key Vault. |
| `storageAccountId` | `string` | — | Resource ID of the associated Storage Account. |
| `applicationInsightsId` | `string` | — | Resource ID of the associated Application Insights. |
| `identityId` | `string` | — | Resource ID of the user-assigned managed identity. |
| `publicNetworkAccess` | `string` | `'Disabled'` | `Enabled` or `Disabled`. |
| `tags` | `object` | `{}` | Tags to apply. |

## Outputs

| Name | Type | Description |
|------|------|-------------|
| `hubId` | `string` | Resource ID of the AI Foundry hub. |
| `projectId` | `string` | Resource ID of the AI Foundry project. |

## Example Usage

```bicep
module foundry 'modules/foundry/main.bicep' = {
  name: 'foundry-deployment'
  params: {
    hubName: 'aihub-foundry-dev-eus2-001'
    projectName: 'aiproj-foundry-dev-eus2-001'
    location: 'eastus2'
    skuName: 'Basic'
    keyVaultId: keyVault.outputs.id
    storageAccountId: storageAccount.outputs.id
    applicationInsightsId: appInsights.outputs.id
    identityId: identity.outputs.id
    publicNetworkAccess: 'Disabled'
    tags: {
      environment: 'dev'
      workload: 'foundry'
    }
  }
}
```
