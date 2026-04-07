# --------------------
# Input Variables
# --------------------

variable "name" {
  description = "The name of the Application Insights resource."
  type        = string
}

variable "resource_group_name" {
  description = "The name of the resource group that contains this resource."
  type        = string
}

variable "location" {
  description = "The Azure region where Application Insights will be created."
  type        = string
}

variable "application_type" {
  description = "The type of application being monitored (e.g. 'web', 'java', 'other')."
  type        = string
  default     = "web"
}

variable "workspace_id" {
  description = "The resource ID of the Log Analytics workspace that backs this instance."
  type        = string
}

variable "tags" {
  description = "A map of tags to apply to Application Insights."
  type        = map(string)
  default     = {}
}
