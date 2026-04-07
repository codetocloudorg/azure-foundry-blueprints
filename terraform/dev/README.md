# Terraform — Dev Spoke Environment

This root module deploys a complete, self-contained Azure AI Foundry dev spoke by orchestrating the reusable modules under `../modules/`.

## What Gets Deployed

| Layer | Resources |
|-------|-----------|
| Foundation | Resource Group, VNet, Subnets, NSGs, Private DNS Zones |
| Platform | Log Analytics, Application Insights, Managed Identity, Key Vault, Storage Account |
| Workload | AI Foundry Hub, AI Foundry Project |
| Connectivity | Private Endpoints for Key Vault, AI Foundry, and Storage |

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
