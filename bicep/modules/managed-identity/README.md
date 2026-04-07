# Managed Identity Module

Creates a user-assigned managed identity for secret-less authentication of Azure resources. Follows the principle of least privilege with RBAC role assignments.

## Resources Deployed

| Resource | Type |
|----------|------|
| User-Assigned Managed Identity | `Microsoft.ManagedIdentity/userAssignedIdentities` |

## Parameters

| Name | Type | Default | Description |
|------|------|---------|-------------|
| `name` | `string` | — | The name of the managed identity (3–128 chars). |
| `location` | `string` | — | The Azure region for deployment. |
| `tags` | `object` | `{}` | Tags to apply. |

## Outputs

| Name | Type | Description |
|------|------|-------------|
| `id` | `string` | The resource ID of the managed identity. |
| `principalId` | `string` | The principal (object) ID for RBAC assignments. |
| `clientId` | `string` | The client (application) ID. |

## Example Usage

```bicep
module identity 'modules/managed-identity/main.bicep' = {
  name: 'managed-identity-deployment'
  params: {
    name: 'id-foundry-dev-eus2-001'
    location: 'eastus2'
    tags: {
      environment: 'dev'
      workload: 'foundry'
    }
  }
}
```
