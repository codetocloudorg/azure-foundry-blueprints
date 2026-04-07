# --------------------
# Input Variables
# --------------------

variable "name" {
  description = "The name of the private DNS zone (e.g. 'privatelink.vaultcore.azure.net')."
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group that contains this DNS zone."
  type        = string
}

variable "virtual_network_id" {
  description = "The ID of the virtual network to link this DNS zone to."
  type        = string
}

variable "tags" {
  description = "A map of tags to apply to the DNS zone."
  type        = map(string)
  default     = {}
}
