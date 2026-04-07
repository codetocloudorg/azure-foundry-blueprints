# --------------------
# Input Variables
# --------------------

variable "name" {
  description = "The name of the user-assigned managed identity."
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group that contains this identity."
  type        = string
}

variable "location" {
  description = "The Azure region where the identity will be created."
  type        = string
}

variable "tags" {
  description = "A map of tags to apply to the managed identity."
  type        = map(string)
  default     = {}
}
