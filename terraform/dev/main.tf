# ==========================================================================
# Dev Spoke — Root Orchestration
# ==========================================================================
# This root module composes every module under ../modules/ into a single,
# self-contained Azure AI Foundry dev spoke.  It contains NO resource
# logic — only module calls and the glue that connects them.
#
# Deployment order (reflects real dependency graph):
#   1. Resource Group
#   2. Virtual Network + Subnets
#   3. Network Security Groups (one per subnet)
#   4. Log Analytics Workspace
#   5. Application Insights
#   6. Managed Identity
#   7. Key Vault
#   8. Storage Account (inline — no module)
#   9. Private DNS Zones
#  10. AI Foundry Hub + Project
#  11. Private Endpoints (Key Vault, AI Foundry)
# ==========================================================================

# --------------------------------------------------------------------------
# Data Sources
# --------------------------------------------------------------------------
# Retrieve the tenant and subscription context of the caller so we can
# configure resources (Key Vault) that require an Azure AD tenant ID.

data "azurerm_client_config" "current" {}

# --------------------------------------------------------------------------
# Locals — Naming Convention & Tags
# --------------------------------------------------------------------------
# Naming pattern: {prefix}-{workload}-{env}-{region_short}-{instance}
# Region-short map keeps names concise. Tags follow the shared tagging
# strategy defined in /shared/tags/README.md.

locals {
  # Short region codes used in resource names.
  region_short_map = {
    eastus2        = "eus2"
    eastus         = "eus"
    westus2        = "wus2"
    westeurope     = "weu"
    northeurope    = "neu"
    swedencentral  = "swc"
    southcentralus = "scus"
  }
  region_short = lookup(local.region_short_map, var.location, var.location)

  # Helper to build a consistent name: {prefix}-{workload}-{env}-{region}-{instance}
  name_prefix = "${var.workload_name}-${var.environment}-${local.region_short}-${var.instance}"

  # Required tags applied to every resource.
  common_tags = {
    environment = var.environment
    workload    = var.workload_name
    owner       = var.owner
    cost-center = var.cost_center
    managed-by  = "terraform"
  }

  # Subnet definitions following /shared/network-design/README.md.
  subnets = [
    {
      name                              = "snet-default"
      address_prefixes                  = ["10.100.0.0/24"]
      private_endpoint_network_policies = "Enabled"
    },
    {
      name                              = "snet-pe"
      address_prefixes                  = ["10.100.1.0/24"]
      private_endpoint_network_policies = "Enabled"
    },
    {
      name                              = "snet-ai"
      address_prefixes                  = ["10.100.2.0/24"]
      private_endpoint_network_policies = "Enabled"
    },
    {
      name                              = "snet-management"
      address_prefixes                  = ["10.100.3.0/24"]
      private_endpoint_network_policies = "Enabled"
    },
  ]

  # Private DNS zones required by the spoke — one per Azure service type
  # that needs private-link resolution.
  #
  # Azure AI Foundry best practices require zones for:
  #  - ML workspace API & notebook compute (azureml, notebooks)
  #  - AI model inference: Cognitive Services, OpenAI, AI Services
  #  - Supporting services: Key Vault, Storage (blob + file), Monitor/Log Analytics
  # See: https://learn.microsoft.com/azure/ai-studio/how-to/configure-private-link
  private_dns_zones = {
    azureml    = "privatelink.api.azureml.ms"                # Foundry Hub ML workspace API
    notebooks  = "privatelink.notebooks.azure.net"           # Compute instances / notebooks
    cognitive  = "privatelink.cognitiveservices.azure.com"   # Cognitive Services
    openai     = "privatelink.openai.azure.com"              # Azure OpenAI
    aiservices = "privatelink.aiservices.azure.com"          # AI Services (unified endpoint)
    vault      = "privatelink.vaultcore.azure.net"           # Key Vault
    blob       = "privatelink.blob.core.windows.net"         # Blob Storage
    file       = "privatelink.file.core.windows.net"         # File Storage (Foundry file shares)
    monitor    = "privatelink.monitor.azure.com"             # Azure Monitor
    ods        = "privatelink.ods.opinsights.azure.com"      # Log Analytics data ingest
    oms        = "privatelink.oms.opinsights.azure.com"      # Log Analytics OMS
    automation = "privatelink.agentsvc.azure-automation.net" # Automation agent service
  }
}

# ==========================================================================
# 1. Resource Group
# ==========================================================================
# Single resource group containing every resource in the dev spoke.

module "resource_group" {
  source = "../modules/resource-group"

  name     = "rg-${local.name_prefix}"
  location = var.location
  tags     = local.common_tags
}

# ==========================================================================
# 2. Virtual Network + Subnets
# ==========================================================================
# Dev spoke VNet with four purpose-specific subnets. No hub peering — this
# spoke is entirely self-contained per the design philosophy.

module "vnet" {
  source = "../modules/vnet"

  name                = "vnet-${local.name_prefix}"
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  address_space       = var.address_space
  subnets             = local.subnets
  tags                = local.common_tags
}

# ==========================================================================
# 3. Network Security Groups — one per subnet
# ==========================================================================
# Each subnet gets its own NSG for micro-segmentation. The module provides
# default deny-internet + allow-vnet rules; add custom_rules as needed.

module "nsg" {
  source   = "../modules/nsg"
  for_each = { for s in local.subnets : s.name => s }

  name                = "nsg-${each.key}-${var.environment}-${local.region_short}-${var.instance}"
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  subnet_id           = module.vnet.subnet_ids[each.key]
  tags                = local.common_tags
}

# ==========================================================================
# 4. Log Analytics Workspace
# ==========================================================================
# Centralised logging sink. All diagnostic settings and Application Insights
# route telemetry here. Deployed before workloads per observability standards.

module "log_analytics" {
  source = "../modules/log-analytics"

  name                = "log-${local.name_prefix}"
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  sku                 = var.log_analytics_sku
  retention_in_days   = var.log_analytics_retention_in_days
  tags                = local.common_tags
}

# ==========================================================================
# 5. Application Insights
# ==========================================================================
# Workspace-based (v2) Application Insights linked to Log Analytics.
# Provides APM telemetry for the AI Foundry workload.

module "app_insights" {
  source = "../modules/app-insights"

  name                = "appi-${local.name_prefix}"
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  application_type    = "web"
  workspace_id        = module.log_analytics.id
  tags                = local.common_tags
}

# ==========================================================================
# 6. Managed Identity
# ==========================================================================
# User-assigned managed identity shared by AI Foundry hub and project.
# Enables RBAC-based access to Key Vault, Storage, and other data-plane
# resources without storing secrets.

module "managed_identity" {
  source = "../modules/managed-identity"

  name                = "id-${local.name_prefix}"
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  tags                = local.common_tags
}

# ==========================================================================
# 7. Key Vault
# ==========================================================================
# Enterprise secret store. Configured with RBAC authorisation (no access
# policies) and purge protection. Public network access disabled — traffic
# flows through the private endpoint on snet-pe.

module "key_vault" {
  source = "../modules/key-vault"

  name                          = "kv-${local.name_prefix}"
  resource_group_name           = module.resource_group.name
  location                      = module.resource_group.location
  tenant_id                     = data.azurerm_client_config.current.tenant_id
  sku_name                      = var.key_vault_sku
  public_network_access_enabled = false
  tags                          = local.common_tags
}

# ==========================================================================
# 8. Storage Account
# ==========================================================================
# Required by the AI Foundry hub for model artefacts and datasets.
# No dedicated module exists so the resource is created inline.
# Name follows the storage-account naming rule (no hyphens, <= 24 chars).

resource "azurerm_storage_account" "this" {
  name                     = "st${var.workload_name}${var.environment}${local.region_short}${var.instance}"
  resource_group_name      = module.resource_group.name
  location                 = module.resource_group.location
  account_tier             = "Standard"
  account_replication_type = "LRS"

  # Security defaults — private networking enforced.
  public_network_access_enabled = false
  min_tls_version               = "TLS1_2"

  tags = local.common_tags
}

# ==========================================================================
# 9. Private DNS Zones
# ==========================================================================
# One zone per Azure service that uses private link. Each zone is linked
# to the spoke VNet so that DNS queries resolve to the private endpoint IP
# instead of the public IP.

module "private_dns" {
  source   = "../modules/private-dns"
  for_each = local.private_dns_zones

  name                = each.value
  resource_group_name = module.resource_group.name
  virtual_network_id  = module.vnet.id
  tags                = local.common_tags
}

# ==========================================================================
# 10. AI Foundry Hub + Project
# ==========================================================================
# The hub is the top-level workspace that holds shared configuration
# (Key Vault, Storage, App Insights). The project is a child workspace
# scoped to the dev team. Public access disabled — all traffic through
# private endpoints.

module "foundry" {
  source = "../modules/foundry"

  hub_name                = "aihub-${local.name_prefix}"
  project_name            = "aiproj-${local.name_prefix}"
  resource_group_name     = module.resource_group.name
  location                = module.resource_group.location
  key_vault_id            = module.key_vault.id
  storage_account_id      = azurerm_storage_account.this.id
  application_insights_id = module.app_insights.id
  identity_ids            = [module.managed_identity.id]
  public_network_access   = "Disabled"
  tags                    = local.common_tags
}

# ==========================================================================
# 11. Private Endpoints
# ==========================================================================
# Private endpoints place a NIC on snet-pe so that traffic to Key Vault,
# AI Foundry, and Storage never traverses the public internet.
# Azure AI Foundry best practices require separate endpoints for the Hub
# workspace, blob storage, and file storage, each linked to ALL relevant
# DNS zones so that every SDK/API call resolves privately.

# --- Key Vault Private Endpoint ---
# Secrets, keys, and certificates used by the Foundry Hub and project.
module "pe_key_vault" {
  source = "../modules/private-endpoint"

  name                           = "pep-kv-${local.name_prefix}"
  resource_group_name            = module.resource_group.name
  location                       = module.resource_group.location
  subnet_id                      = module.vnet.subnet_ids["snet-pe"]
  private_connection_resource_id = module.key_vault.id
  subresource_names              = ["vault"]
  private_dns_zone_ids           = [module.private_dns["vault"].id]
  tags                           = local.common_tags
}

# --- AI Foundry Hub Private Endpoint ---
# The Foundry Hub (amlworkspace sub-resource) requires DNS zones for the ML
# workspace API, notebook compute, and all AI inference services (Cognitive
# Services, OpenAI, AI Services) so that SDK calls, notebook traffic, and
# model endpoints all resolve to private IPs.
module "pe_foundry" {
  source = "../modules/private-endpoint"

  name                           = "pep-aihub-${local.name_prefix}"
  resource_group_name            = module.resource_group.name
  location                       = module.resource_group.location
  subnet_id                      = module.vnet.subnet_ids["snet-pe"]
  private_connection_resource_id = module.foundry.hub_id
  subresource_names              = ["amlworkspace"]
  private_dns_zone_ids = [
    module.private_dns["azureml"].id,
    module.private_dns["notebooks"].id,
    module.private_dns["cognitive"].id,
    module.private_dns["openai"].id,
    module.private_dns["aiservices"].id,
  ]
  tags = local.common_tags
}

# --- Storage Account (Blob) Private Endpoint ---
# Blob storage holds model artefacts, datasets, and pipeline outputs.
module "pe_storage_blob" {
  source = "../modules/private-endpoint"

  name                           = "pep-st-blob-${local.name_prefix}"
  resource_group_name            = module.resource_group.name
  location                       = module.resource_group.location
  subnet_id                      = module.vnet.subnet_ids["snet-pe"]
  private_connection_resource_id = azurerm_storage_account.this.id
  subresource_names              = ["blob"]
  private_dns_zone_ids           = [module.private_dns["blob"].id]
  tags                           = local.common_tags
}

# --- Storage Account (File) Private Endpoint ---
# Azure AI Foundry mounts file shares for code snapshots, logs, and shared
# datasets. A dedicated file sub-resource endpoint ensures SMB/REST traffic
# stays on the private network.
module "pe_storage_file" {
  source = "../modules/private-endpoint"

  name                           = "pep-st-file-${local.name_prefix}"
  resource_group_name            = module.resource_group.name
  location                       = module.resource_group.location
  subnet_id                      = module.vnet.subnet_ids["snet-pe"]
  private_connection_resource_id = azurerm_storage_account.this.id
  subresource_names              = ["file"]
  private_dns_zone_ids           = [module.private_dns["file"].id]
  tags                           = local.common_tags
}
