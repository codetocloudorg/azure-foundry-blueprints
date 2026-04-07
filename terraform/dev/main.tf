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
  # Aligned with Azure AI Landing Zones subnet strategy.
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
  # Microsoft Foundry (new architecture) requires zones for:
  #  - Cognitive Services, OpenAI, AI Services (unified endpoint)
  #  - Supporting services: Key Vault, Storage (blob + file), Monitor/Log Analytics
  #  - Agent standard resources: Cosmos DB, AI Search (D-R1 best practice)
  # See: https://learn.microsoft.com/azure/foundry/how-to/configure-private-link
  private_dns_zones = {
    cognitive  = "privatelink.cognitiveservices.azure.com"   # Cognitive Services
    openai     = "privatelink.openai.azure.com"              # Azure OpenAI
    aiservices = "privatelink.aiservices.azure.com"          # AI Services (unified endpoint)
    vault      = "privatelink.vaultcore.azure.net"           # Key Vault
    blob       = "privatelink.blob.core.windows.net"         # Blob Storage
    file       = "privatelink.file.core.windows.net"         # File Storage
    monitor    = "privatelink.monitor.azure.com"             # Azure Monitor
    ods        = "privatelink.ods.opinsights.azure.com"      # Log Analytics data ingest
    oms        = "privatelink.oms.opinsights.azure.com"      # Log Analytics OMS
    automation = "privatelink.agentsvc.azure-automation.net" # Automation agent service
    cosmosdb   = "privatelink.documents.azure.com"           # Cosmos DB (Agent state)
    search     = "privatelink.search.windows.net"            # AI Search (Vector retrieval)
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
# 2a. NAT Gateway — Internet Egress Path
# ==========================================================================
# Provides outbound internet connectivity for resources in the spoke VNet.
# Without this (or a hub firewall), private resources cannot reach the internet
# for package downloads, API calls to external services, etc.
# Associated with snet-ai where workloads run.

resource "azurerm_public_ip" "nat" {
  name                = "pip-nat-${local.name_prefix}"
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  allocation_method   = "Static"
  sku                 = "Standard"
  zones               = ["1", "2", "3"]
  tags                = local.common_tags
}

resource "azurerm_nat_gateway" "this" {
  name                    = "nat-${local.name_prefix}"
  resource_group_name     = module.resource_group.name
  location                = module.resource_group.location
  sku_name                = "Standard"
  idle_timeout_in_minutes = 10
  zones                   = ["1"]
  tags                    = local.common_tags
}

resource "azurerm_nat_gateway_public_ip_association" "this" {
  nat_gateway_id       = azurerm_nat_gateway.this.id
  public_ip_address_id = azurerm_public_ip.nat.id
}

resource "azurerm_subnet_nat_gateway_association" "ai" {
  subnet_id      = module.vnet.subnet_ids["snet-ai"]
  nat_gateway_id = azurerm_nat_gateway.this.id
}

resource "azurerm_subnet_nat_gateway_association" "default" {
  subnet_id      = module.vnet.subnet_ids["snet-default"]
  nat_gateway_id = azurerm_nat_gateway.this.id
}

resource "azurerm_subnet_nat_gateway_association" "management" {
  subnet_id      = module.vnet.subnet_ids["snet-management"]
  nat_gateway_id = azurerm_nat_gateway.this.id
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
  public_network_access_enabled   = false
  min_tls_version                 = "TLS1_2"
  shared_access_key_enabled       = false  # Azure AD auth only (policy requirement)
  default_to_oauth_authentication = true

  tags = local.common_tags
}

# ==========================================================================
# 8a. RBAC Role Assignments for Managed Identity
# ==========================================================================
# AI Foundry requires the managed identity to have data plane access to
# storage (blob + file) and secrets access to Key Vault. These must be
# granted BEFORE the Foundry Hub is created.

resource "azurerm_role_assignment" "identity_storage_blob" {
  scope                = azurerm_storage_account.this.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = module.managed_identity.principal_id
}

resource "azurerm_role_assignment" "identity_storage_file" {
  scope                = azurerm_storage_account.this.id
  role_definition_name = "Storage File Data Privileged Contributor"
  principal_id         = module.managed_identity.principal_id
}

resource "azurerm_role_assignment" "identity_keyvault" {
  scope                = module.key_vault.id
  role_definition_name = "Key Vault Secrets Officer"
  principal_id         = module.managed_identity.principal_id
}

# ==========================================================================
# 8b. Diagnostic Settings (M-R4: Logs/Metrics → Log Analytics)
# ==========================================================================
# Per AI Landing Zone design checklist, all resources should send diagnostic
# logs and metrics to Log Analytics for centralized monitoring.

resource "azurerm_monitor_diagnostic_setting" "storage" {
  name                       = "diag-storage-${local.name_prefix}"
  target_resource_id         = azurerm_storage_account.this.id
  log_analytics_workspace_id = module.log_analytics.id

  enabled_metric {
    category = "Transaction"
  }

  enabled_metric {
    category = "Capacity"
  }
}

resource "azurerm_monitor_diagnostic_setting" "keyvault" {
  name                       = "diag-kv-${local.name_prefix}"
  target_resource_id         = module.key_vault.id
  log_analytics_workspace_id = module.log_analytics.id

  enabled_log {
    category = "AuditEvent"
  }

  enabled_log {
    category = "AzurePolicyEvaluationDetails"
  }

  enabled_metric {
    category = "AllMetrics"
  }
}

# ==========================================================================
# 8c. Azure Cosmos DB — Agent State Storage (D-R1)
# ==========================================================================
# Per AI Landing Zones design checklist (D-R1): Use standard setup of Agent
# service and store data in your own Azure resources. Cosmos DB stores
# threads, messages, and runs for stateful agent scenarios.

resource "azurerm_cosmosdb_account" "this" {
  name                = "cosmos-${local.name_prefix}"
  resource_group_name = module.resource_group.name
  location            = module.resource_group.location
  offer_type          = "Standard"
  kind                = "GlobalDocumentDB"

  # Security — private networking, no public access
  public_network_access_enabled     = false
  is_virtual_network_filter_enabled = true
  local_authentication_disabled     = true # Use Azure AD only

  consistency_policy {
    consistency_level = "Session"
  }

  geo_location {
    location          = module.resource_group.location
    failover_priority = 0
  }

  # Backup policy
  backup {
    type = "Continuous"
    tier = "Continuous7Days"
  }

  tags = local.common_tags
}

resource "azurerm_cosmosdb_sql_database" "agents" {
  name                = "agents"
  resource_group_name = module.resource_group.name
  account_name        = azurerm_cosmosdb_account.this.name
}

resource "azurerm_cosmosdb_sql_container" "threads" {
  name                = "threads"
  resource_group_name = module.resource_group.name
  account_name        = azurerm_cosmosdb_account.this.name
  database_name       = azurerm_cosmosdb_sql_database.agents.name
  partition_key_paths = ["/threadId"]
  throughput          = 400
}

# RBAC for managed identity → Cosmos DB
resource "azurerm_cosmosdb_sql_role_assignment" "identity_cosmos" {
  resource_group_name = module.resource_group.name
  account_name        = azurerm_cosmosdb_account.this.name
  role_definition_id  = "${azurerm_cosmosdb_account.this.id}/sqlRoleDefinitions/00000000-0000-0000-0000-000000000002" # Cosmos DB Built-in Data Contributor
  principal_id        = module.managed_identity.principal_id
  scope               = azurerm_cosmosdb_account.this.id
}

# ==========================================================================
# 8d. Azure AI Search — Vector Retrieval (D-R1)
# ==========================================================================
# AI Search provides embeddings and retrieval for RAG patterns.
# Used by Foundry agents for knowledge grounding.

resource "azurerm_search_service" "this" {
  name                          = "srch-${local.name_prefix}"
  resource_group_name           = module.resource_group.name
  location                      = module.resource_group.location
  sku                           = "standard"
  public_network_access_enabled = false
  local_authentication_enabled  = false # Azure AD only

  identity {
    type = "SystemAssigned"
  }

  tags = local.common_tags
}

# RBAC for managed identity → AI Search
resource "azurerm_role_assignment" "identity_search_contrib" {
  scope                = azurerm_search_service.this.id
  role_definition_name = "Search Index Data Contributor"
  principal_id         = module.managed_identity.principal_id
}

resource "azurerm_role_assignment" "identity_search_reader" {
  scope                = azurerm_search_service.this.id
  role_definition_name = "Search Index Data Reader"
  principal_id         = module.managed_identity.principal_id
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
# 10. Microsoft Foundry (New Architecture)
# ==========================================================================
# The NEW Microsoft Foundry uses Microsoft.CognitiveServices/account with 
# kind AIServices. This replaces the legacy hub-based model.
# Projects are subresources created within the Foundry account.
# Public access disabled — all traffic through private endpoints.

module "foundry" {
  source = "../modules/foundry"

  foundry_name          = "aisvcs-${local.name_prefix}"
  project_name          = "proj-${local.name_prefix}"
  project_description   = "Development project for ${var.workload_name}"
  custom_subdomain_name = "aisvcs-${var.workload_name}-${var.environment}-${local.region_short}-${var.instance}"
  resource_group_name   = module.resource_group.name
  location              = module.resource_group.location
  sku_name              = "S0"
  identity_ids          = [module.managed_identity.id]
  public_network_access = "Disabled"
  tags                  = local.common_tags

  depends_on = [
    azurerm_role_assignment.identity_storage_blob,
    azurerm_role_assignment.identity_storage_file,
    azurerm_role_assignment.identity_keyvault
  ]
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

# --- Microsoft Foundry Private Endpoint ---
# The new Foundry (Cognitive Services) uses "account" sub-resource.
# DNS zones for Cognitive Services, OpenAI, and AI Services ensure
# all API calls resolve to private IPs.
module "pe_foundry" {
  source = "../modules/private-endpoint"

  name                           = "pep-aisvcs-${local.name_prefix}"
  resource_group_name            = module.resource_group.name
  location                       = module.resource_group.location
  subnet_id                      = module.vnet.subnet_ids["snet-pe"]
  private_connection_resource_id = module.foundry.id
  subresource_names              = ["account"]
  private_dns_zone_ids = [
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

# --- Cosmos DB Private Endpoint ---
# Agent state storage (threads, messages, runs) accessed privately.
module "pe_cosmosdb" {
  source = "../modules/private-endpoint"

  name                           = "pep-cosmos-${local.name_prefix}"
  resource_group_name            = module.resource_group.name
  location                       = module.resource_group.location
  subnet_id                      = module.vnet.subnet_ids["snet-pe"]
  private_connection_resource_id = azurerm_cosmosdb_account.this.id
  subresource_names              = ["Sql"]
  private_dns_zone_ids           = [module.private_dns["cosmosdb"].id]
  tags                           = local.common_tags
}

# --- AI Search Private Endpoint ---
# Vector search and knowledge retrieval for RAG patterns.
module "pe_search" {
  source = "../modules/private-endpoint"

  name                           = "pep-srch-${local.name_prefix}"
  resource_group_name            = module.resource_group.name
  location                       = module.resource_group.location
  subnet_id                      = module.vnet.subnet_ids["snet-pe"]
  private_connection_resource_id = azurerm_search_service.this.id
  subresource_names              = ["searchService"]
  private_dns_zone_ids           = [module.private_dns["search"].id]
  tags                           = local.common_tags
}
