# Azure Foundry Blueprints

Enterprise-ready Azure AI Foundry deployment blueprints using **Bicep** and **Terraform**, aligned with modern Microsoft cloud architecture standards and [Azure AI Landing Zone](https://github.com/Azure/AI-Landing-Zones) best practices.

## Overview

This repository provides a developer-focused, enterprise-style reference implementation for deploying [Azure AI Foundry](https://learn.microsoft.com/en-us/azure/ai-studio/) using Infrastructure-as-Code. It deploys a self-contained dev spoke environment with private networking, observability, and security defaults.

> **Note:** This is for development and learning — not a production landing zone.

## What Gets Deployed

| Resource                    | Purpose                              |
|-----------------------------|--------------------------------------|
| Resource Group              | Container for all resources          |
| Virtual Network             | 4 segmented subnets (`/16`)          |
| Network Security Groups     | Default-deny microsegmentation       |
| Log Analytics Workspace     | Centralized logging                  |
| Application Insights        | AI Foundry telemetry                 |
| User-Assigned Managed Identity | Least-privilege identity           |
| Key Vault                   | Secrets, RBAC-authorized             |
| Storage Account             | Foundry workspace storage            |
| Azure AI Foundry Hub        | AI services hub                      |
| Azure AI Foundry Project    | AI project workspace                 |
| 12 Private DNS Zones        | Private endpoint name resolution     |
| 4 Private Endpoints         | Key Vault, Blob, File, AI Foundry    |

## Repository Structure

```
azure-foundry-blueprints/
├── bicep/
│   ├── modules/          # Reusable Bicep modules
│   └── dev/              # Dev environment deployment
├── terraform/
│   ├── modules/          # Reusable Terraform modules
│   └── dev/              # Dev environment deployment
├── docs/
│   ├── architecture.md   # Architecture overview
│   ├── networking.md     # Networking deep dive
│   └── observability.md  # Observability strategy
├── shared/
│   ├── naming/           # Naming conventions
│   ├── tags/             # Tagging strategy
│   └── network-design/   # Network address planning
├── scripts/
│   ├── bootstrap/        # Azure environment setup
│   └── validate/         # Pre-deploy validation
└── .github/workflows/    # CI validation pipelines
```

## Quick Start

### Prerequisites

- [Azure CLI](https://learn.microsoft.com/en-us/cli/azure/install-azure-cli) with Bicep extension
- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.5
- An Azure subscription with Owner or Contributor access

### 1. Bootstrap Azure Environment

```bash
./scripts/bootstrap/setup-azure.sh
```

### 2. Deploy with Terraform

```bash
cd terraform/dev
terraform init
terraform plan -var-file="dev.tfvars"
terraform apply -var-file="dev.tfvars"
```

### 3. Deploy with Bicep

```bash
cd bicep/dev
az deployment sub create \
  --location eastus2 \
  --template-file main.bicep \
  --parameters main.bicepparam
```

## Design Principles

- **Private networking first** — All PaaS services accessed via private endpoints
- **Secure by default** — RBAC, managed identities, encryption enabled
- **Observable** — Log Analytics + App Insights deployed before workloads
- **Modular** — Single-responsibility modules, reusable across environments
- **Terraform/Bicep parity** — Both flavours deploy identical architectures
- **Enterprise patterns** — Layered architecture preserved even for dev

## Documentation

- [Architecture](docs/architecture.md) — Platform layering, resource inventory, deployment order
- [Networking](docs/networking.md) — VNet design, subnets, DNS zones, private endpoints
- [Observability](docs/observability.md) — Logging, monitoring, diagnostic settings
- [Contributing](CONTRIBUTING.md) — How to contribute

## References

- [Azure AI Landing Zones](https://github.com/Azure/AI-Landing-Zones)
- [Azure AI Foundry Private Networking](https://learn.microsoft.com/en-us/azure/foundry/how-to/configure-private-link)
- [Azure Private Endpoint DNS](https://learn.microsoft.com/en-us/azure/private-link/private-endpoint-dns)
- [Cloud Adoption Framework — AI Scenario](https://learn.microsoft.com/en-us/azure/cloud-adoption-framework/scenarios/ai/)

