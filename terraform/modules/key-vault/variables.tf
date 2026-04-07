# --------------------
# Input Variables
# --------------------

variable "name" {
  description = "The name of the Key Vault. Must be globally unique (3–24 chars, alphanumeric and hyphens)."
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group that contains this Key Vault."
  type        = string
}

variable "location" {
  description = "The Azure region where the Key Vault will be created."
  type        = string
}

variable "tenant_id" {
  description = "The Azure AD tenant ID for the Key Vault."
  type        = string
}

variable "sku_name" {
  description = "The SKU of the Key Vault ('standard' or 'premium')."
  type        = string
  default     = "standard"
}

variable "public_network_access_enabled" {
  description = "Whether public network access is enabled. Set to false for private-only access."
  type        = bool
  default     = false
}

variable "tags" {
  description = "A map of tags to apply to the Key Vault."
  type        = map(string)
  default     = {}
}
