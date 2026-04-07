# Naming Convention

## Format

All Azure resources follow this naming pattern:

```
{resource-prefix}-{workload}-{environment}-{region-short}-{instance}
```

### Components

| Component        | Description                        | Example       |
|------------------|------------------------------------|---------------|
| resource-prefix  | Azure resource type abbreviation   | `rg`, `vnet`  |
| workload         | Workload or project name           | `foundry`     |
| environment      | Deployment environment             | `dev`         |
| region-short     | Azure region short code            | `eus2`        |
| instance         | Optional instance number           | `001`         |

### Resource Prefixes

| Resource                    | Prefix   |
|-----------------------------|----------|
| Resource Group              | `rg`     |
| Virtual Network             | `vnet`   |
| Subnet                      | `snet`   |
| Network Security Group      | `nsg`    |
| Private Endpoint            | `pep`    |
| Private DNS Zone            | `pdnsz`  |
| Log Analytics Workspace     | `log`    |
| Application Insights        | `appi`   |
| Key Vault                   | `kv`     |
| Managed Identity            | `id`     |
| AI Foundry Hub              | `aihub`  |
| AI Foundry Project          | `aiproj` |
| Storage Account             | `st`     |

### Examples

```
rg-foundry-dev-eus2-001
vnet-foundry-dev-eus2-001
snet-foundry-dev-eus2-pe
kv-foundry-dev-eus2-001
aihub-foundry-dev-eus2-001
```

> **Note:** Storage account names must be lowercase, 3-24 characters, no hyphens.
> Use format: `st{workload}{env}{region}{instance}` → `stfoundrydeveus2001`
