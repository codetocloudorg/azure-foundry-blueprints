# --------------------
# Input Variables
# --------------------

variable "name" {
  description = "The name of the Log Analytics workspace."
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group that contains this workspace."
  type        = string
}

variable "location" {
  description = "The Azure region where the workspace will be created."
  type        = string
}

variable "sku" {
  description = "The SKU (pricing tier) for the workspace."
  type        = string
  default     = "PerGB2018"
}

variable "retention_in_days" {
  description = "The number of days to retain log data (30–730)."
  type        = number
  default     = 30
}

variable "tags" {
  description = "A map of tags to apply to the workspace."
  type        = map(string)
  default     = {}
}
