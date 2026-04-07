# Azure AI Foundry Module
# -----------------------
# Creates an Azure AI Foundry hub and project using the modern
# azurerm_ai_foundry and azurerm_ai_foundry_project resources.
#
# The hub is the top-level workspace that holds shared configuration
# (Key Vault, Storage, App Insights, networking). Projects are
# child workspaces scoped to a specific team or use case.
#
# NOTE: azurerm_ai_foundry and azurerm_ai_foundry_project are the
# preferred resources (available in azurerm >= 4.x). If your provider
# version does not support them, you would fall back to
# azurerm_cognitive_account with kind = "AIServices", but that approach
# does not support hub/project semantics natively.

resource "azurerm_ai_foundry" "this" {
  name                = var.hub_name
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags

  # Public network access is a string: "Enabled" or "Disabled".
  # Disabled by default — access through private endpoints only.
  public_network_access = var.public_network_access

  # Core dependencies — the hub manages these shared resources for all projects.
  key_vault_id            = var.key_vault_id
  storage_account_id      = var.storage_account_id
  application_insights_id = var.application_insights_id

  identity {
    type         = "UserAssigned"
    identity_ids = var.identity_ids
  }
}

resource "azurerm_ai_foundry_project" "this" {
  name               = var.project_name
  ai_services_hub_id = azurerm_ai_foundry.this.id
  location           = var.location
  tags               = var.tags

  identity {
    type         = "UserAssigned"
    identity_ids = var.identity_ids
  }
}
