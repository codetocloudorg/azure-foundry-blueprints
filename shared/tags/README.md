# Tagging Strategy

## Required Tags

All resources **must** include these tags:

| Tag Key       | Description                          | Example                |
|---------------|--------------------------------------|------------------------|
| `environment` | Deployment environment               | `dev`                  |
| `workload`    | Workload or project identifier       | `foundry`              |
| `owner`       | Team or individual responsible       | `platform-team`        |
| `cost-center` | Cost allocation identifier           | `cc-12345`             |
| `managed-by`  | IaC tool managing the resource       | `terraform` or `bicep` |

## Optional Tags

| Tag Key        | Description                         | Example                |
|----------------|-------------------------------------|------------------------|
| `created-date` | Date of initial deployment          | `2026-04-07`           |
| `data-class`   | Data classification                 | `internal`             |
| `criticality`  | Business criticality                | `low`                  |

## Implementation

### Terraform

```hcl
locals {
  common_tags = {
    environment = var.environment
    workload    = var.workload_name
    owner       = var.owner
    cost-center = var.cost_center
    managed-by  = "terraform"
  }
}
```

### Bicep

```bicep
var commonTags = {
  environment: environment
  workload: workloadName
  owner: owner
  'cost-center': costCenter
  'managed-by': 'bicep'
}
```

> **Note:** Tags are propagated from the root module/deployment to all child resources.
