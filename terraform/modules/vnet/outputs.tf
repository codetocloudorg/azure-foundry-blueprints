# --------------------
# Outputs
# --------------------

output "id" {
  description = "The ID of the virtual network."
  value       = azurerm_virtual_network.this.id
}

output "name" {
  description = "The name of the virtual network."
  value       = azurerm_virtual_network.this.name
}

# Map of subnet name → subnet ID for easy downstream lookups.
output "subnet_ids" {
  description = "A map of subnet names to their resource IDs."
  value       = { for k, v in azurerm_subnet.this : k => v.id }
}
