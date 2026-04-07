# --------------------
# Input Variables
# --------------------

variable "name" {
  description = "The name of the network security group."
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group that contains this NSG."
  type        = string
}

variable "location" {
  description = "The Azure region where the NSG will be created."
  type        = string
}

variable "subnet_id" {
  description = "The ID of the subnet to associate this NSG with."
  type        = string
}

variable "custom_rules" {
  description = "A list of custom security rules to add to the NSG beyond the defaults."
  type = list(object({
    name                       = string
    priority                   = number
    direction                  = string
    access                     = string
    protocol                   = string
    source_port_range          = string
    destination_port_range     = string
    source_address_prefix      = string
    destination_address_prefix = string
  }))
  default = []
}

variable "tags" {
  description = "A map of tags to apply to the NSG."
  type        = map(string)
  default     = {}
}
