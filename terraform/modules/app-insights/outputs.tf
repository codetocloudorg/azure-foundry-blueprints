# --------------------
# Outputs
# --------------------

output "id" {
  description = "The resource ID of the Application Insights instance."
  value       = azurerm_application_insights.this.id
}

output "instrumentation_key" {
  description = "The instrumentation key used to connect telemetry producers."
  value       = azurerm_application_insights.this.instrumentation_key
  sensitive   = true
}

output "connection_string" {
  description = "The connection string for Application Insights."
  value       = azurerm_application_insights.this.connection_string
  sensitive   = true
}
