# --------------------
# Outputs
# --------------------

output "id" {
  description = "The resource ID of the user-assigned managed identity."
  value       = azurerm_user_assigned_identity.this.id
}

output "principal_id" {
  description = "The principal (object) ID of the managed identity, used for RBAC role assignments."
  value       = azurerm_user_assigned_identity.this.principal_id
}

output "client_id" {
  description = "The client (application) ID of the managed identity."
  value       = azurerm_user_assigned_identity.this.client_id
}
