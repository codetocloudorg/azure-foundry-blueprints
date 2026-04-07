# Managed Identity Module
# -----------------------
# Creates a user-assigned managed identity. This identity is used to
# authenticate Azure resources (e.g. Foundry, Key Vault) without secrets,
# following the principle of least privilege with RBAC role assignments.

resource "azurerm_user_assigned_identity" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  tags                = var.tags
}
