# Terraform — Dev Spoke Environment

> **⚠️ Disclaimer:** This code is provided as-is, with no warranties or guarantees. Use at your own risk.

## 🚀 Deploys the New Foundry Experience

This deployment creates the **NEW Microsoft Foundry portal experience** — not the classic Azure AI Studio hub-based model.

- **Foundry Account**: `Microsoft.CognitiveServices/accounts` with `allowProjectManagement: true`
- **Foundry Project**: `Microsoft.CognitiveServices/accounts/projects` (new project type)

We use the **AzAPI provider** because the new Foundry properties aren't yet available in AzureRM. This gives us access to the `2025-06-01` API version with full support for the new architecture.

```mermaid
flowchart LR
    subgraph old["Classic"]
        hub["ML Workspace\nHub"]
        proj_old["ML Workspace\nProject"]
        hub --> proj_old
    end
    
    subgraph new["This Deployment"]
        foundry["Cognitive Services\nAIServices"]
        proj_new["Foundry Project"]
        foundry --> proj_new
    end
    
    style new fill:#d4edda,stroke:#28a745,color:#000
    style old fill:#f8d7da,stroke:#dc3545,color:#000
    style foundry fill:#0078d4,color:#000
    style proj_new fill:#50e6ff,color:#000
    style hub fill:#ffcccc,color:#000
    style proj_old fill:#ffcccc,color:#000
```

## What Gets Deployed

```mermaid
flowchart TB
    subgraph foundation["1. Foundation"]
        rg["Resource Group"]
        vnet["VNet + Subnets"]
        nsg["NSGs"]
        dns["Private DNS Zones"]
    end
    
    subgraph platform["2. Platform"]
        log["Log Analytics"]
        appi["App Insights"]
        id["Managed Identity"]
        kv["Key Vault"]
        st["Storage Account"]
    end
    
    subgraph workload["3. Workload"]
        foundry["Microsoft Foundry"]
        project["Foundry Project"]
        foundry --> project
    end
    
    subgraph connectivity["4. Connectivity"]
        pe["Private Endpoints"]
    end
    
    foundation --> platform --> workload --> connectivity
    
    style workload fill:#cce5ff,stroke:#0078d4,color:#000
    style foundry fill:#0078d4,color:#000
    style project fill:#50e6ff,color:#000
```

| Layer | Resources |
|-------|----------|
| Foundation | Resource Group, VNet, Subnets, NSGs, Private DNS Zones |
| Platform | Log Analytics, Application Insights, Managed Identity, Key Vault, Storage Account |
| Workload | Microsoft Foundry (AI Services + Project) |
| Connectivity | Private Endpoints for Key Vault, Storage, Foundry |

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.5
- [Azure CLI](https://learn.microsoft.com/cli/azure/install-azure-cli) >= 2.50
- An active Azure subscription
- Logged in: `az login`

## Quick Start

```bash
# 1. Initialise Terraform (downloads providers)
terraform init

# 2. Review the execution plan
terraform plan -var-file="dev.tfvars"

# 3. Apply the deployment
terraform apply -var-file="dev.tfvars"
```

## Customisation

Override any variable in `dev.tfvars` or pass values via CLI:

```bash
terraform plan -var-file="dev.tfvars" -var="location=swedencentral"
```

See [`variables.tf`](variables.tf) for the full list of inputs and their defaults.

## Remote State (Optional)

Uncomment the `backend "azurerm"` block in [`providers.tf`](providers.tf) and configure it for your storage account:

```bash
terraform init \
  -backend-config="resource_group_name=rg-terraform-state" \
  -backend-config="storage_account_name=stterraformstate" \
  -backend-config="container_name=tfstate" \
  -backend-config="key=foundry-dev.tfstate"
```

## Tear Down

```bash
terraform destroy -var-file="dev.tfvars"
```

## Naming Convention

All resources follow the pattern `{prefix}-{workload}-{env}-{region_short}-{instance}`. See [`/shared/naming/README.md`](../../shared/naming/README.md) for details.
