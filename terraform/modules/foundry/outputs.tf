# --------------------
# Outputs
# --------------------

output "hub_id" {
  description = "The resource ID of the Azure AI Foundry hub."
  value       = azurerm_ai_foundry.this.id
}

output "project_id" {
  description = "The resource ID of the Azure AI Foundry project."
  value       = azurerm_ai_foundry_project.this.id
}

output "hub_endpoint" {
  description = "The endpoint URL of the Azure AI Foundry hub."
  value       = azurerm_ai_foundry.this.discovery_url
}
