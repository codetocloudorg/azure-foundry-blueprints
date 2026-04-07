# --------------------
# Input Variables
# --------------------

variable "hub_name" {
  description = "The name of the Azure AI Foundry hub."
  type        = string
}

variable "project_name" {
  description = "The name of the Azure AI Foundry project (child of the hub)."
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group that contains the Foundry resources."
  type        = string
}

variable "location" {
  description = "The Azure region where the Foundry hub and project will be created."
  type        = string
}

variable "key_vault_id" {
  description = "The resource ID of the Key Vault associated with the hub."
  type        = string
}

variable "storage_account_id" {
  description = "The resource ID of the Storage Account associated with the hub."
  type        = string
}

variable "application_insights_id" {
  description = "The resource ID of the Application Insights instance associated with the hub."
  type        = string
}

variable "identity_ids" {
  description = "A list of user-assigned managed identity IDs to attach to the hub and project."
  type        = list(string)
}

variable "public_network_access" {
  description = "Whether public network access is enabled ('Enabled' or 'Disabled')."
  type        = string
  default     = "Disabled"

  validation {
    condition     = contains(["Enabled", "Disabled"], var.public_network_access)
    error_message = "public_network_access must be either 'Enabled' or 'Disabled'."
  }
}

variable "tags" {
  description = "A map of tags to apply to the Foundry resources."
  type        = map(string)
  default     = {}
}
