# Resource Group Module
# ---------------------
# Creates an Azure Resource Group — the logical container for all resources
# deployed within this spoke environment.

resource "azurerm_resource_group" "this" {
  name     = var.name
  location = var.location
  tags     = var.tags
}
