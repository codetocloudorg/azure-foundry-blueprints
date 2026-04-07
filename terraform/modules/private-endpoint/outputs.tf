# --------------------
# Outputs
# --------------------

output "id" {
  description = "The resource ID of the private endpoint."
  value       = azurerm_private_endpoint.this.id
}

# The private IP address assigned to the endpoint NIC, useful for
# debugging connectivity and verifying DNS resolution.
output "private_ip_address" {
  description = "The private IP address allocated to the private endpoint."
  value       = azurerm_private_endpoint.this.private_service_connection[0].private_ip_address
}
