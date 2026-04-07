# --------------------
# Input Variables
# --------------------

variable "name" {
  description = "The name of the virtual network."
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group that contains this VNet."
  type        = string
}

variable "location" {
  description = "The Azure region where the VNet will be created."
  type        = string
}

variable "address_space" {
  description = "The address space (CIDR blocks) for the virtual network."
  type        = list(string)
  default     = ["10.100.0.0/16"]
}

variable "subnets" {
  description = "A list of subnet definitions to create within the VNet."
  type = list(object({
    name                              = string
    address_prefixes                  = list(string)
    private_endpoint_network_policies = optional(string, "Enabled")
  }))
  default = []
}

variable "tags" {
  description = "A map of tags to apply to the virtual network."
  type        = map(string)
  default     = {}
}
