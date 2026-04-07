# Networking

This document describes the networking architecture of **azure-foundry-blueprints** — a private-by-default, zero-public-IP design that isolates all resources within a single Virtual Network.

---

## Design Principles

- **No public IPs** — no resource is directly reachable from the internet
- **No service endpoints** — private endpoints are the only PaaS connectivity mechanism
- **Default deny** — NSGs block all inbound internet traffic by default
- **Purpose-specific subnets** — each subnet serves a defined function
- **Private DNS resolution** — all PaaS FQDNs resolve to private IPs within the VNet

---

## Virtual Network

| Property | Value |
|----------|-------|
| Name | `vnet-foundry-dev-{region}-001` |
| Address Space | `10.100.0.0/16` |
| Usable IPs | 65,536 |
| Region | Configurable (single region deployment) |

The `/16` address space provides room for future subnet expansion while keeping the dev environment self-contained. This VNet has no peering connections and no gateway — it is a standalone spoke.

---

## Subnets

Four subnets segment traffic by purpose. Each subnet has its own Network Security Group.

| Subnet | CIDR | Usable IPs | Purpose |
|--------|------|------------|---------|
| `snet-default` | `10.100.0.0/24` | 251 | General-purpose workloads |
| `snet-pe` | `10.100.1.0/24` | 251 | Private endpoints for PaaS services |
| `snet-ai` | `10.100.2.0/24` | 251 | AI Foundry compute and integration |
| `snet-management` | `10.100.3.0/24` | 251 | Management, bastion, and operations (future) |

### Subnet Address Map

```
10.100.0.0/16 (VNet)
│
├── 10.100.0.0/24    snet-default       General workloads
├── 10.100.1.0/24    snet-pe            Private endpoints
├── 10.100.2.0/24    snet-ai            AI Foundry compute
├── 10.100.3.0/24    snet-management    Management / bastion
│
└── 10.100.4.0/24    (unallocated — available for expansion)
    ...
    10.100.255.0/24  (unallocated)
```

### Subnet Configuration Notes

- **`snet-pe`** has private endpoint network policies configured to allow private endpoint placement. This is the only subnet where private endpoints should be deployed.
- **`snet-ai`** is reserved for AI Foundry compute resources and managed compute instances.
- **`snet-management`** is reserved for future management tooling such as Azure Bastion or jump boxes.
- All subnets are created as discrete resources (not inline in the VNet definition) to allow independent module references.

---

## Network Security Groups

Every subnet is associated with a Network Security Group (NSG). NSGs enforce a default-deny posture with explicit allow rules.

### Default Rules (Applied to All NSGs)

| Rule Name | Priority | Direction | Access | Protocol | Source | Destination |
|-----------|----------|-----------|--------|----------|--------|-------------|
| `AllowVNetInbound` | 100 | Inbound | **Allow** | `*` | `VirtualNetwork` | `VirtualNetwork` |
| `DenyInternetInbound` | 4096 | Inbound | **Deny** | `*` | `Internet` | `*` |

### Security Posture

- **Inbound from internet** — denied by default at priority 4096 (near the bottom of the rule list, only overridden by explicit higher-priority allows)
- **Inbound VNet-to-VNet** — allowed at priority 100, enabling communication between subnets
- **Outbound** — Azure default rules allow outbound traffic; custom rules can restrict as needed
- **Custom rules** — the NSG module accepts a `custom_rules` parameter for environment-specific requirements

### NSG Design Rationale

The default deny rule uses priority 4096 (not 4096) so that custom allow rules can be inserted at any priority between 101–4095 without conflicting. VNet-to-VNet is allowed because private endpoints in `snet-pe` must be reachable from workloads in other subnets.

---

## Private Endpoints

All PaaS services are accessed through private endpoints. A private endpoint creates a network interface with a private IP address in `snet-pe`, making the service reachable only from within the VNet.

### Private Endpoint Architecture

```
┌──────────────┐         ┌──────────────┐         ┌──────────────────────┐
│  Workload in  │   ───►  │  Private      │   ───►  │  PaaS Service         │
│  snet-ai      │  VNet   │  Endpoint in  │  Azure  │  (Key Vault, Storage, │
│               │  route  │  snet-pe      │  back-  │   AI Foundry, etc.)   │
│               │         │  10.100.1.x   │  plane  │                       │
└──────────────┘         └──────────────┘         └──────────────────────┘
                                │
                                ▼
                    ┌──────────────────────┐
                    │  Private DNS Zone      │
                    │  FQDN → 10.100.1.x    │
                    └──────────────────────┘
```

### Resources with Private Endpoints

| Resource | Subresource | Private DNS Zone |
|----------|------------|-----------------|
| Key Vault | `vault` | `privatelink.vaultcore.azure.net` |
| Storage Account | `blob` | `privatelink.blob.core.windows.net` |
| AI Foundry (Cognitive Services) | `account` | `privatelink.cognitiveservices.azure.com` |
| Log Analytics | `query` | `privatelink.ods.opinsights.azure.com` |
| Application Insights | `query` | `privatelink.monitor.azure.com` |
| Azure Monitor | `agent` | `privatelink.agentsvc.azure-automation.net` |

### Private Endpoint Module

The `private-endpoint` module creates:

1. An `azurerm_private_endpoint` resource in the specified subnet
2. A `private_dns_zone_group` linking the endpoint to the appropriate Private DNS Zone
3. Automatic DNS A-record registration so the service FQDN resolves to the private IP

---

## Private DNS Zones

Private DNS zones enable FQDN resolution to private IP addresses within the VNet. Without them, PaaS service FQDNs would resolve to public IPs, bypassing the private endpoints.

### DNS Zones Deployed

| DNS Zone | Service | Example FQDN |
|----------|---------|---------------|
| `privatelink.cognitiveservices.azure.com` | AI Services / Foundry | `myservice.cognitiveservices.azure.com` |
| `privatelink.vaultcore.azure.net` | Key Vault | `myvault.vault.azure.net` |
| `privatelink.blob.core.windows.net` | Blob Storage | `mystorage.blob.core.windows.net` |
| `privatelink.monitor.azure.com` | Azure Monitor | `monitor.monitor.azure.com` |
| `privatelink.ods.opinsights.azure.com` | Log Analytics (data) | `workspace.ods.opinsights.azure.com` |
| `privatelink.oms.opinsights.azure.com` | Log Analytics (management) | `workspace.oms.opinsights.azure.com` |
| `privatelink.agentsvc.azure-automation.net` | Azure Automation Agent | `agent.agentsvc.azure-automation.net` |

### DNS Resolution Flow

```
1. Workload queries: myvault.vault.azure.net
2. Azure DNS checks VNet-linked Private DNS Zone: privatelink.vaultcore.azure.net
3. Zone returns CNAME → myvault.privatelink.vaultcore.azure.net
4. A-record resolves to: 10.100.1.x (private endpoint IP in snet-pe)
5. Traffic stays within the VNet — never touches the public internet
```

### DNS Zone Configuration

- All zones are linked to the VNet with `registration_enabled = false` (auto-registration is not used; records are created by private endpoint DNS zone groups)
- Each zone is a standalone module instance, making it easy to add zones for new services
- Zone linking ensures any resource in the VNet can resolve private endpoints

---

## Traffic Flows

### Allowed Traffic

| From | To | Path | Why |
|------|----|------|-----|
| `snet-ai` workload | Key Vault | `snet-ai` → `snet-pe` private endpoint → Key Vault | Retrieve secrets for AI workloads |
| `snet-ai` workload | Storage (blob) | `snet-ai` → `snet-pe` private endpoint → Storage | Read/write model artifacts |
| `snet-ai` workload | AI Foundry | `snet-ai` → `snet-pe` private endpoint → Foundry | API calls to Foundry services |
| Any subnet | Log Analytics | VNet → `snet-pe` private endpoint → Log Analytics | Diagnostic data ingestion |
| Any subnet | Any subnet | VNet-to-VNet (NSG allows) | Inter-subnet communication |

### Denied Traffic

| From | To | Blocked By |
|------|----|-----------|
| Internet | Any subnet | NSG `DenyInternetInbound` (priority 4096) |
| External client | Key Vault public endpoint | `public_network_access_enabled = false` |
| External client | AI Foundry public endpoint | `public_network_access = "Disabled"` |

---

## Adding a New PaaS Resource

When contributing a new PaaS resource to the blueprint, follow these steps to maintain the networking posture:

1. **Disable public access** on the resource (`public_network_access_enabled = false` or equivalent)
2. **Create a private endpoint** using the `private-endpoint` module, placed in `snet-pe`
3. **Add a Private DNS Zone** if one does not already exist for the service (check [Azure Private DNS zone values](https://learn.microsoft.com/en-us/azure/private-link/private-endpoint-dns))
4. **Link the DNS zone** to the VNet using the `private-dns` module
5. **Connect the endpoint to the DNS zone** via the private DNS zone group in the endpoint configuration
6. **Update this document** with the new resource, DNS zone, and traffic flow
