# --------------------------------------------------------------------------
# Outputs — Dev Spoke
# --------------------------------------------------------------------------
# Key values surfaced after deployment. Use these for downstream automation,
# CI/CD pipelines, or quick verification of deployed resources.

# ---- Resource Group ----

output "resource_group_name" {
  description = "Name of the dev spoke resource group."
  value       = module.resource_group.name
}

output "resource_group_id" {
  description = "Resource ID of the dev spoke resource group."
  value       = module.resource_group.id
}

# ---- Networking ----

output "vnet_id" {
  description = "Resource ID of the spoke virtual network."
  value       = module.vnet.id
}

output "vnet_name" {
  description = "Name of the spoke virtual network."
  value       = module.vnet.name
}

output "subnet_ids" {
  description = "Map of subnet name → subnet resource ID."
  value       = module.vnet.subnet_ids
}

# ---- Observability ----

output "log_analytics_workspace_id" {
  description = "Resource ID of the Log Analytics workspace."
  value       = module.log_analytics.id
}

output "app_insights_connection_string" {
  description = "Application Insights connection string (use for SDK configuration)."
  value       = module.app_insights.connection_string
  sensitive   = true
}

# ---- Identity ----

output "managed_identity_id" {
  description = "Resource ID of the user-assigned managed identity."
  value       = module.managed_identity.id
}

output "managed_identity_principal_id" {
  description = "Principal (object) ID of the managed identity — use for RBAC assignments."
  value       = module.managed_identity.principal_id
}

output "managed_identity_client_id" {
  description = "Client (application) ID of the managed identity."
  value       = module.managed_identity.client_id
}

# ---- Key Vault ----

output "key_vault_id" {
  description = "Resource ID of the Key Vault."
  value       = module.key_vault.id
}

output "key_vault_uri" {
  description = "Vault URI (e.g. https://<name>.vault.azure.net/)."
  value       = module.key_vault.vault_uri
}

output "key_vault_name" {
  description = "Name of the Key Vault."
  value       = module.key_vault.name
}

# ---- Storage Account ----

output "storage_account_id" {
  description = "Resource ID of the storage account used by AI Foundry."
  value       = azurerm_storage_account.this.id
}

output "storage_account_name" {
  description = "Name of the storage account."
  value       = azurerm_storage_account.this.name
}

# ---- AI Foundry ----

output "foundry_hub_id" {
  description = "Resource ID of the AI Foundry hub."
  value       = module.foundry.hub_id
}

output "foundry_project_id" {
  description = "Resource ID of the AI Foundry project."
  value       = module.foundry.project_id
}

output "foundry_hub_endpoint" {
  description = "Discovery URL (endpoint) for the AI Foundry hub."
  value       = module.foundry.hub_endpoint
}

# ---- Private Endpoints ----

output "pe_key_vault_private_ip" {
  description = "Private IP address of the Key Vault private endpoint."
  value       = module.pe_key_vault.private_ip_address
}

output "pe_foundry_private_ip" {
  description = "Private IP address of the AI Foundry private endpoint."
  value       = module.pe_foundry.private_ip_address
}

output "pe_storage_blob_private_ip" {
  description = "Private IP address of the Storage blob private endpoint."
  value       = module.pe_storage_blob.private_ip_address
}
