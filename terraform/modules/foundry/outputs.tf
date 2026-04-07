# --------------------
# Outputs — Microsoft Foundry (New Architecture)
# --------------------

output "id" {
  description = "The resource ID of the Microsoft Foundry resource."
  value       = azapi_resource.foundry.id
}

output "endpoint" {
  description = "The endpoint URL of the Microsoft Foundry resource."
  value       = "https://${var.custom_subdomain_name}.cognitiveservices.azure.com/"
}

output "principal_id" {
  description = "The principal ID of the system-assigned managed identity."
  value       = try(azapi_resource.foundry.identity[0].principal_id, null)
}

output "project_id" {
  description = "The resource ID of the Foundry project (if created)."
  value       = var.project_name != null ? azapi_resource.project[0].id : null
}
