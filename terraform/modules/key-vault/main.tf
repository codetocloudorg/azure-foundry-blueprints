# Key Vault Module
# ----------------
# Creates an Azure Key Vault with RBAC-based authorization (no access policies),
# purge protection enabled, and public network access disabled by default.
# This follows enterprise security best practices for secret management.

resource "azurerm_key_vault" "this" {
  name                = var.name
  resource_group_name = var.resource_group_name
  location            = var.location
  tenant_id           = var.tenant_id
  sku_name            = var.sku_name
  tags                = var.tags

  # Use Azure RBAC for access control instead of vault access policies.
  # This integrates with the platform's identity model and supports
  # conditional access, PIM, and audit logging natively.
  rbac_authorization_enabled = true

  # Purge protection prevents permanent deletion of secrets during the
  # soft-delete retention period — required for enterprise compliance.
  purge_protection_enabled = true

  # Disable public access by default; access is through private endpoints only.
  public_network_access_enabled = var.public_network_access_enabled
}
