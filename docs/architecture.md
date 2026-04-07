# Architecture Overview

This document describes the enterprise architecture of **azure-foundry-blueprints** — a self-contained dev spoke environment that deploys Azure AI Foundry with private networking, observability, and security guardrails.

> **Note:** This is a dev/learning environment. It preserves enterprise architecture patterns without requiring production dependencies like a hub VNet, ExpressRoute, or centralized firewall.

---

## Platform Layering Model

Enterprise Azure architectures organize resources into layers of responsibility. This project preserves that model even in a single dev deployment, so developers learn the patterns they will encounter in production.

| Layer | Enterprise Purpose | Dev Implementation |
|-------|-------------------|-------------------|
| **Foundation** | Shared infrastructure owned by platform team | Resource Group, VNet, NSGs |
| **Platform** | Shared services consumed by workloads | Log Analytics, App Insights, Key Vault, Managed Identity |
| **Workload** | Application-specific resources | AI Foundry Hub + Project, Storage Account |
| **Environment** | Environment-specific configuration | Dev only (single environment) |

In production, these layers are often separate subscriptions or resource groups with distinct RBAC boundaries. Here, all layers deploy into a single resource group for simplicity, but the module structure preserves the separation.

---

## Self-Contained Dev Spoke

This architecture is a **self-contained spoke** — it does not depend on a hub VNet, VPN gateway, or peering connection. Everything needed to run AI Foundry privately is included in the deployment.

**What this means:**

- No hub-and-spoke dependency — deploy without a central networking team
- No peering — the VNet stands alone with its own private DNS resolution
- No ExpressRoute or VPN — access is within the VNet only
- No centralized firewall — NSGs provide per-subnet security

This makes the blueprint deployable by a single developer in under 15 minutes, while still demonstrating the patterns used in enterprise landing zones.

---

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  Resource Group (rg-foundry-dev-{region}-001)                               │
│                                                                             │
│  ┌────────────────────────────────────────────────────────────────────────┐  │
│  │  VNet: 10.100.0.0/16                                                  │  │
│  │                                                                        │  │
│  │  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐     │  │
│  │  │  snet-default     │  │  snet-pe          │  │  snet-ai          │     │  │
│  │  │  10.100.0.0/24    │  │  10.100.1.0/24    │  │  10.100.2.0/24    │     │  │
│  │  │  General workloads│  │  Private endpoints │  │  AI Foundry       │     │  │
│  │  │  [NSG]            │  │  [NSG]            │  │  compute [NSG]    │     │  │
│  │  └──────────────────┘  └────────┬───────────┘  └──────────────────┘     │  │
│  │                                  │                                       │  │
│  │  ┌──────────────────┐           │                                       │  │
│  │  │  snet-management  │           │  Private Endpoints                    │  │
│  │  │  10.100.3.0/24    │           │  ┌─────────────────────┐             │  │
│  │  │  Management [NSG] │           ├──│ Key Vault            │             │  │
│  │  └──────────────────┘           ├──│ Storage (Blob)       │             │  │
│  │                                  ├──│ AI Foundry           │             │  │
│  └──────────────────────────────────├──│ Log Analytics        │─────────┘  │
│                                     ├──│ App Insights         │             │
│                                     └──│ Azure Monitor        │             │
│  ┌──────────────────────────────┐      └─────────────────────┘             │
│  │  Private DNS Zones            │                                          │
│  │  *.cognitiveservices.azure.com│  ┌──────────────────────────────────┐   │
│  │  *.vaultcore.azure.net        │  │  AI Foundry Hub                   │   │
│  │  *.blob.core.windows.net      │  │  ├── AI Foundry Project           │   │
│  │  *.monitor.azure.com          │  │  ├── Key Vault (secrets)          │   │
│  │  *.ods.opinsights.azure.com   │  │  ├── Storage Account (artifacts)  │   │
│  │  *.oms.opinsights.azure.com   │  │  ├── App Insights (telemetry)     │   │
│  │  *.agentsvc.azure-automation  │  │  └── Managed Identity (auth)      │   │
│  │  .net                         │  └──────────────────────────────────┘   │
│  └──────────────────────────────┘                                          │
│                                                                             │
│  ┌──────────────────────────────┐  ┌──────────────────────────────────┐   │
│  │  Log Analytics Workspace      │  │  Application Insights             │   │
│  │  SKU: PerGB2018               │  │  Type: workspace-based (v2)       │   │
│  │  Retention: 30 days           │  │  Backend: Log Analytics            │   │
│  └──────────────────────────────┘  └──────────────────────────────────┘   │
│                                                                             │
│  ┌──────────────────────────────┐                                          │
│  │  Managed Identity              │                                          │
│  │  Type: User-Assigned           │                                          │
│  │  Used by: AI Foundry Hub/Proj  │                                          │
│  └──────────────────────────────┘                                          │
└─────────────────────────────────────────────────────────────────────────────┘
```

---

## Resource Inventory

### Foundation Layer

| Resource | Naming Pattern | Purpose |
|----------|---------------|---------|
| Resource Group | `rg-foundry-dev-{region}-001` | Container for all resources |
| Virtual Network | `vnet-foundry-dev-{region}-001` | Network isolation (10.100.0.0/16) |
| Subnets (4) | `snet-{purpose}` | Workload segmentation |
| NSGs | `nsg-{subnet-name}` | Per-subnet traffic control |
| Private DNS Zones (7) | `privatelink.{service}.{domain}` | Private name resolution |

### Platform Layer

| Resource | Naming Pattern | Purpose |
|----------|---------------|---------|
| Log Analytics Workspace | `log-foundry-dev-{region}` | Centralized log collection |
| Application Insights | `appi-foundry-dev-{region}` | Application telemetry |
| Key Vault | `kv-foundry-dev-{region}` | Secrets and certificate management |
| Managed Identity | `id-foundry-dev-{region}` | Workload authentication (user-assigned) |

### Workload Layer

| Resource | Naming Pattern | Purpose |
|----------|---------------|---------|
| AI Foundry Hub | `aih-foundry-dev-{region}` | Central AI workspace |
| AI Foundry Project | `aip-foundry-dev-{region}` | Project within the hub |
| Storage Account | `stfoundrydev{region}001` | Model and artifact storage |
| Private Endpoints | `pep-{resource}` | Private connectivity to PaaS services |

---

## Deployment Order

Resources must be deployed in a specific order to satisfy dependencies. The module structure reflects this ordering.

```
Phase 1 — Foundation
│
├── 1. Resource Group
│      No dependencies. Container for everything else.
│
├── 2. Virtual Network + Subnets
│      Depends on: Resource Group
│
├── 3. Network Security Groups
│      Depends on: Subnets (associated per subnet)
│
└── 4. Private DNS Zones
       Depends on: Resource Group, VNet (linked for resolution)

Phase 2 — Platform Services
│
├── 5. Log Analytics Workspace
│      Depends on: Resource Group
│      Deployed early — other resources send diagnostics here.
│
├── 6. Application Insights
│      Depends on: Log Analytics Workspace (workspace-based backend)
│
├── 7. Key Vault
│      Depends on: Resource Group
│      RBAC-only, purge protection enabled, public access disabled.
│
└── 8. Managed Identity
       Depends on: Resource Group
       User-assigned identity consumed by AI Foundry.

Phase 3 — Workload
│
├── 9.  Storage Account
│       Depends on: Resource Group
│       Required by AI Foundry for model/artifact storage.
│
├── 10. AI Foundry Hub
│       Depends on: Key Vault, Storage Account, App Insights, Managed Identity
│       Public network access disabled.
│
├── 11. AI Foundry Project
│       Depends on: AI Foundry Hub (child resource)
│
└── 12. Private Endpoints
        Depends on: snet-pe subnet, target resources, Private DNS Zones
        Created after resources exist so endpoint connections can be established.
```

---

## Module Dependency Graph

```
resource-group
├── vnet
│   └── nsg (per subnet)
├── private-dns (linked to vnet)
├── log-analytics
│   └── app-insights
├── key-vault
├── managed-identity
├── private-endpoint (snet-pe, target resources, dns zones)
└── foundry
    ├── hub (key-vault, storage, app-insights, managed-identity)
    └── project (hub)
```

---

## Design Decisions

### Why a self-contained spoke?

Enterprise landing zones typically use hub-and-spoke with centralized DNS, firewall, and connectivity. That pattern requires coordination across teams and subscriptions. This blueprint deploys everything in one spoke so a single developer can stand up the full environment independently, while still learning the resource relationships and security patterns.

### Why user-assigned managed identity?

User-assigned identities are created independently of the resources that use them. This allows the identity to be provisioned in an earlier deployment phase and referenced by multiple resources (Hub and Project), making the dependency chain explicit and the identity lifecycle independent.

### Why RBAC-only on Key Vault?

Access policies are the legacy authorization model. RBAC provides consistent Azure-wide authorization, integrates with Managed Identity, supports conditional access, and aligns with enterprise governance. This blueprint enforces RBAC-only (`enable_rbac_authorization = true`) with no access policies.

### Why deploy observability before workloads?

Log Analytics and Application Insights are created in Phase 2 so that workload resources in Phase 3 can immediately send diagnostic data. This avoids a gap where resources exist but are not observable — a common mistake in real deployments.
