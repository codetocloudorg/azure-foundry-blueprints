# Observability

This document describes the observability strategy for **azure-foundry-blueprints** — how logs, metrics, and telemetry are collected, stored, and connected across the dev spoke environment.

---

## Design Principles

- **Deploy observability before workloads** — Log Analytics and Application Insights are provisioned in Phase 2 so that workload resources can send data from the moment they are created
- **Centralized collection** — all diagnostic data flows to a single Log Analytics Workspace
- **Workspace-based Application Insights** — uses the modern v2 architecture backed by Log Analytics, not the legacy standalone model
- **Diagnostic settings on all resources** — every resource that supports diagnostic settings should send logs and metrics to the workspace
- **Private connectivity** — observability services are accessed through private endpoints, keeping telemetry traffic within the VNet

---

## Observability Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                                                                     │
│   ┌──────────────┐   ┌──────────────┐   ┌──────────────────────┐  │
│   │  AI Foundry    │   │  Key Vault    │   │  Other Resources     │  │
│   │  Hub + Project │   │               │   │  (VNet, NSG, etc.)   │  │
│   └──────┬─────────┘   └──────┬────────┘   └──────┬───────────────┘  │
│          │                     │                    │                  │
│          │  Diagnostic         │  Diagnostic        │  Diagnostic     │
│          │  Settings           │  Settings           │  Settings       │
│          ▼                     ▼                    ▼                  │
│   ┌────────────────────────────────────────────────────────────────┐  │
│   │                  Log Analytics Workspace                       │  │
│   │                  SKU: PerGB2018                                │  │
│   │                  Retention: 30 days                            │  │
│   │                                                                │  │
│   │  ┌─────────────────┐  ┌─────────────────┐  ┌──────────────┐ │  │
│   │  │  Resource Logs    │  │  Metrics          │  │  Activity     │ │  │
│   │  │  (diagnostics)    │  │  (platform)       │  │  Logs         │ │  │
│   │  └─────────────────┘  └─────────────────┘  └──────────────┘ │  │
│   └──────────────────────────────┬─────────────────────────────────┘  │
│                                  │                                    │
│                                  │ Workspace backend                  │
│                                  ▼                                    │
│   ┌────────────────────────────────────────────────────────────────┐  │
│   │                  Application Insights (v2)                     │  │
│   │                  Type: workspace-based                         │  │
│   │                  Application Type: web                         │  │
│   │                                                                │  │
│   │  ┌─────────────────┐  ┌─────────────────┐  ┌──────────────┐ │  │
│   │  │  Requests         │  │  Dependencies     │  │  Exceptions   │ │  │
│   │  │  & Traces         │  │  & Performance    │  │  & Failures   │ │  │
│   │  └─────────────────┘  └─────────────────┘  └──────────────┘ │  │
│   └────────────────────────────────────────────────────────────────┘  │
│                                                                       │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Components

### Log Analytics Workspace

The central data store for all observability data in the spoke.

| Property | Value |
|----------|-------|
| Naming Pattern | `log-foundry-dev-{region}` |
| SKU | `PerGB2018` (pay-per-GB ingestion) |
| Retention | 30 days (configurable, 30–730 days) |
| Deployment Phase | Phase 2 — Platform Services |
| Private Access | Via private endpoints in `snet-pe` |

**Key outputs consumed by other modules:**

| Output | Used By | Purpose |
|--------|---------|---------|
| `id` | Application Insights | Workspace backend for telemetry storage |
| `id` | Diagnostic settings | Destination for resource logs and metrics |
| `workspace_id` | Queries and dashboards | GUID for programmatic access |
| `primary_shared_key` | Agent configuration | Authentication (sensitive) |

### Application Insights

Application-level telemetry for AI Foundry workloads.

| Property | Value |
|----------|-------|
| Naming Pattern | `appi-foundry-dev-{region}` |
| Application Type | `web` |
| Architecture | Workspace-based (v2) |
| Backend | Log Analytics Workspace |
| Deployment Phase | Phase 2 — Platform Services (after Log Analytics) |

**Why workspace-based?**

Classic (standalone) Application Insights stores data in its own proprietary backend with limited retention and query capabilities. Workspace-based Application Insights stores all data in Log Analytics, providing:

- Unified querying across application telemetry and infrastructure logs
- Consistent retention policies
- Cross-resource correlation using Kusto (KQL)
- Single pane of glass for the entire spoke

**Key outputs consumed by other modules:**

| Output | Used By | Purpose |
|--------|---------|---------|
| `id` | AI Foundry Hub | Connect telemetry pipeline |
| `instrumentation_key` | Application code | SDK telemetry reporting (sensitive) |
| `connection_string` | Application code | Modern SDK connection (sensitive) |

### AI Foundry Integration

The AI Foundry Hub is created with an explicit reference to the Application Insights instance:

```
AI Foundry Hub
├── application_insights_id → Application Insights
├── key_vault_id → Key Vault
├── storage_account_id → Storage Account
└── identity → Managed Identity
```

This connection enables:

- Automatic telemetry collection from Foundry API calls
- Request tracing and dependency tracking
- Performance monitoring for model inference
- Error and exception logging

---

## Diagnostic Settings

Every Azure resource that supports diagnostic settings should be configured to send data to the Log Analytics Workspace. This ensures centralized visibility across the entire spoke.

### Resources Requiring Diagnostic Settings

| Resource | Log Categories | Metrics |
|----------|---------------|---------|
| Key Vault | `AuditEvent`, `AzurePolicyEvaluationDetails` | `AllMetrics` |
| AI Foundry Hub | `RequestResponse`, `Audit` | `AllMetrics` |
| Virtual Network | `VMProtectionAlerts` | `AllMetrics` |
| NSGs | `NetworkSecurityGroupEvent`, `NetworkSecurityGroupRuleCounter` | — |
| Storage Account | `StorageRead`, `StorageWrite`, `StorageDelete` | `Transaction` |

### Diagnostic Settings Pattern

Each resource's diagnostic settings should specify:

1. **Target workspace** — the Log Analytics Workspace `id`
2. **Log categories** — all available categories enabled
3. **Metrics** — `AllMetrics` enabled where supported
4. **Retention** — inherited from the workspace (30 days default)

---

## Private Observability Access

Observability services are accessed through private endpoints, consistent with the blueprint's zero-public-IP posture.

### Private DNS Zones for Observability

| Service | DNS Zone | Purpose |
|---------|----------|---------|
| Azure Monitor | `privatelink.monitor.azure.com` | Monitor data ingestion |
| Log Analytics (data) | `privatelink.ods.opinsights.azure.com` | Log and metric ingestion |
| Log Analytics (management) | `privatelink.oms.opinsights.azure.com` | Workspace management API |
| Azure Automation Agent | `privatelink.agentsvc.azure-automation.net` | Agent service communication |

### Data Flow

```
Resource (diagnostic settings)
    │
    ▼
Private Endpoint (snet-pe, 10.100.1.x)
    │
    ▼
Log Analytics Workspace
    │
    ▼
Application Insights (workspace-based, same data store)
```

All telemetry traffic stays within the VNet. No diagnostic data traverses the public internet.

---

## Querying and Correlation

With all data in a single Log Analytics Workspace, you can use Kusto Query Language (KQL) to correlate across resources:

```kusto
// AI Foundry request latency correlated with Key Vault access
let foundry_requests = AppRequests
| where AppRoleName contains "foundry"
| project OperationId, RequestDuration = DurationMs, TimeGenerated;

let kv_operations = AzureDiagnostics
| where ResourceProvider == "MICROSOFT.KEYVAULT"
| project OperationId = CorrelationId, KVDuration = DurationMs, TimeGenerated;

foundry_requests
| join kind=leftouter kv_operations on OperationId
| summarize avg(RequestDuration), avg(KVDuration) by bin(TimeGenerated, 5m)
```

---

## Deployment Considerations

### Order Matters

Observability resources are deployed in **Phase 2 — Platform Services**, before any workload resources in Phase 3. This ensures:

1. Log Analytics Workspace exists before any resource needs to send diagnostics
2. Application Insights exists before AI Foundry Hub is created (Hub requires the App Insights ID)
3. No gap in telemetry — resources are observable from the moment they are provisioned

### Dependency Chain

```
Log Analytics Workspace (Phase 2, Step 5)
    │
    ├──► Application Insights (Phase 2, Step 6)
    │       │
    │       └──► AI Foundry Hub (Phase 3, Step 10)
    │
    └──► Diagnostic Settings (applied to all Phase 2 and Phase 3 resources)
```

### Retention and Cost

- **Default retention:** 30 days (configurable up to 730 days via the `retention_in_days` variable)
- **SKU:** `PerGB2018` — pay-per-GB ingestion, no commitment tier
- **Cost optimization:** for dev environments, 30 days retention and PerGB2018 SKU keep costs minimal while maintaining full observability

---

## Adding Observability to New Resources

When contributing a new resource to the blueprint:

1. **Add a diagnostic setting** that sends logs and metrics to the Log Analytics Workspace
2. **Enable all log categories** available for the resource type
3. **Enable `AllMetrics`** where supported
4. **Use the workspace `id` output** from the `log-analytics` module as the destination
5. **Update this document** with the new resource's log categories and metrics
