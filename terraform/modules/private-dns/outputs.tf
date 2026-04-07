# --------------------
# Outputs
# --------------------

output "id" {
  description = "The resource ID of the private DNS zone."
  value       = azurerm_private_dns_zone.this.id
}

output "name" {
  description = "The name of the private DNS zone."
  value       = azurerm_private_dns_zone.this.name
}
