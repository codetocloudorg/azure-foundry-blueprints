# --------------------
# Input Variables
# --------------------

variable "name" {
  description = "The name of the resource group."
  type        = string
}

variable "location" {
  description = "The Azure region where the resource group will be created (e.g. 'swedencentral')."
  type        = string
}

variable "tags" {
  description = "A map of tags to apply to the resource group."
  type        = map(string)
  default     = {}
}
