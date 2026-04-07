# Network Design

## Address Space

The dev spoke uses a single `/16` address space segmented into purpose-specific subnets.

### VNet Address Space

| VNet             | CIDR            |
|------------------|-----------------|
| Dev Spoke VNet   | `10.100.0.0/16` |

### Subnet Allocation

| Subnet Name       | CIDR              | Purpose                                  |
|--------------------|-------------------|------------------------------------------|
| `snet-default`     | `10.100.0.0/24`   | General workloads                        |
| `snet-pe`          | `10.100.1.0/24`   | Private endpoints                        |
| `snet-ai`          | `10.100.2.0/24`   | AI Foundry compute / integration         |
| `snet-management`  | `10.100.3.0/24`   | Management and bastion (future)          |

### Design Decisions

- **Private endpoints** get their own dedicated subnet (`snet-pe`)
- **AI workloads** isolated in `snet-ai` for future compute integration
- **No public IP** resources are deployed
- **NSG per subnet** for microsegmentation
- **Service endpoints** disabled — private endpoints used exclusively

## Private DNS Zones

| DNS Zone                                        | Purpose                              |
|-------------------------------------------------|--------------------------------------|
| `privatelink.api.azureml.ms`                     | AI Foundry Hub (ML workspace)        |
| `privatelink.notebooks.azure.net`                | AI Foundry compute & notebooks       |
| `privatelink.cognitiveservices.azure.com`        | Cognitive Services                   |
| `privatelink.openai.azure.com`                   | Azure OpenAI endpoints               |
| `privatelink.aiservices.azure.com`               | Azure AI Services                    |
| `privatelink.vaultcore.azure.net`                | Key Vault                            |
| `privatelink.blob.core.windows.net`              | Blob Storage                         |
| `privatelink.file.core.windows.net`              | File Storage (Foundry workspace files) |
| `privatelink.monitor.azure.com`                  | Azure Monitor                        |
| `privatelink.ods.opinsights.azure.com`           | Log Analytics                        |
| `privatelink.oms.opinsights.azure.com`           | Log Analytics OMS                    |
| `privatelink.agentsvc.azure-automation.net`      | Automation                           |

## NSG Rules

Default deny-all with explicit allow rules:

- Allow VNet-to-VNet traffic
- Allow outbound to Azure Monitor
- Deny all inbound from internet
- Deny all outbound to internet (except required Azure services)

> **Note:** This is a dev spoke — no hub or peering. All networking is self-contained.
