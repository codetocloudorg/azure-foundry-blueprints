# --------------------
# Outputs
# --------------------

output "id" {
  description = "The resource ID of the Key Vault."
  value       = azurerm_key_vault.this.id
}

output "vault_uri" {
  description = "The URI of the Key Vault (e.g. https://<name>.vault.azure.net/)."
  value       = azurerm_key_vault.this.vault_uri
}

output "name" {
  description = "The name of the Key Vault."
  value       = azurerm_key_vault.this.name
}
