# --------------------
# Input Variables
# --------------------

variable "name" {
  description = "The name of the private endpoint."
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group that contains this private endpoint."
  type        = string
}

variable "location" {
  description = "The Azure region where the private endpoint will be created."
  type        = string
}

variable "subnet_id" {
  description = "The ID of the subnet where the private endpoint NIC will be placed."
  type        = string
}

variable "private_connection_resource_id" {
  description = "The resource ID of the target Azure resource to connect to privately."
  type        = string
}

variable "subresource_names" {
  description = "The subresource names on the target resource (e.g. ['vault'], ['blob'])."
  type        = list(string)
}

variable "private_dns_zone_ids" {
  description = "A list of private DNS zone IDs to register the endpoint's IP address in."
  type        = list(string)
}

variable "tags" {
  description = "A map of tags to apply to the private endpoint."
  type        = map(string)
  default     = {}
}
