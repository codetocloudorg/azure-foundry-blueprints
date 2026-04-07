# --------------------
# Input Variables — Microsoft Foundry (New Architecture)
# --------------------

variable "foundry_name" {
  description = "The name of the Microsoft Foundry resource (AI Services account)."
  type        = string
}

variable "project_name" {
  description = "The name of the Foundry project. Set to null to skip project creation."
  type        = string
  default     = null
}

variable "project_description" {
  description = "Description for the Foundry project."
  type        = string
  default     = "Development project"
}

variable "resource_group_name" {
  description = "The name of the resource group that contains the Foundry resources."
  type        = string
}

variable "location" {
  description = "The Azure region where the Foundry resource will be created."
  type        = string
}

variable "sku_name" {
  description = "The SKU for the AI Services account (e.g., S0, S1)."
  type        = string
  default     = "S0"
}

variable "custom_subdomain_name" {
  description = "Custom subdomain name for the Foundry endpoint. Must be globally unique."
  type        = string
}

variable "identity_ids" {
  description = "A list of user-assigned managed identity IDs to attach to the Foundry resource."
  type        = list(string)
  default     = null
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

variable "disable_local_auth" {
  description = "Disable API key authentication (use managed identity only)."
  type        = bool
  default     = false
}

variable "tags" {
  description = "A map of tags to apply to the Foundry resources."
  type        = map(string)
  default     = {}
}
