# Log Analytics Workspace Module
# --------------------------------
# Creates a Log Analytics workspace for centralized logging and monitoring.
# This workspace serves as the data sink for Application Insights and
# diagnostic settings across all resources in the spoke.

resource "azurerm_log_analytics_workspace" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  sku                 = var.sku
  retention_in_days   = var.retention_in_days
  tags                = var.tags
}
