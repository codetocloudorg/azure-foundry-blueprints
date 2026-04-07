# Microsoft Foundry Module (New Architecture)
# --------------------------------------------
# Creates a Microsoft Foundry resource using the NEW architecture based on
# Microsoft.CognitiveServices/account with kind "AIServices".
#
# IMPORTANT: Uses AzAPI provider to set `allowProjectManagement = true`
# which enables the NEW Foundry portal experience (not classic).
#
# Reference: https://learn.microsoft.com/en-us/azure/foundry/how-to/create-resource-terraform

terraform {
  required_providers {
    azapi = {
      source  = "Azure/azapi"
      version = ">= 2.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.0"
    }
  }
}

resource "azapi_resource" "foundry" {
  type                      = "Microsoft.CognitiveServices/accounts@2025-06-01"
  name                      = var.foundry_name
  parent_id                 = "/subscriptions/${data.azurerm_client_config.current.subscription_id}/resourceGroups/${var.resource_group_name}"
  location                  = var.location
  schema_validation_enabled = false

  body = {
    kind = "AIServices"
    sku = {
      name = var.sku_name
    }

    identity = {
      type                   = var.identity_ids != null && length(var.identity_ids) > 0 ? "SystemAssigned, UserAssigned" : "SystemAssigned"
      userAssignedIdentities = var.identity_ids != null && length(var.identity_ids) > 0 ? { for id in var.identity_ids : id => {} } : null
    }

    properties = {
      # Enable the NEW Foundry portal experience (not classic hub-based)
      allowProjectManagement = true

      # Custom subdomain for DNS names created for this Foundry resource
      customSubDomainName = var.custom_subdomain_name

      # Network isolation — disabled for enterprise deployments
      publicNetworkAccess = var.public_network_access

      # Disable local auth if using managed identity only
      disableLocalAuth = var.disable_local_auth
    }
  }

  tags = var.tags
}

# Data source to get current subscription ID
data "azurerm_client_config" "current" {}

# Foundry Project — development boundary inside the Foundry resource
# Projects provide isolation for teams to build agents, evaluations, and AI apps.
resource "azapi_resource" "project" {
  count                     = var.project_name != null ? 1 : 0
  type                      = "Microsoft.CognitiveServices/accounts/projects@2025-06-01"
  name                      = var.project_name
  parent_id                 = azapi_resource.foundry.id
  location                  = var.location
  schema_validation_enabled = false

  body = {
    sku = {
      name = var.sku_name
    }
    identity = {
      type = "SystemAssigned"
    }
    properties = {
      displayName = var.project_name
      description = var.project_description
    }
  }

  tags = var.tags
}
