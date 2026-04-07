# Application Insights Module
# ----------------------------
# Creates an Application Insights instance backed by a Log Analytics workspace.
# The workspace-based mode (v2) is required — classic mode is deprecated.
# This provides telemetry and APM for Azure Foundry and connected services.

resource "azurerm_application_insights" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  application_type    = var.application_type
  workspace_id        = var.workspace_id
  tags                = var.tags
}
