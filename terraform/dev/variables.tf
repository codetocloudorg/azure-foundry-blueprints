# --------------------------------------------------------------------------
# Input Variables — Dev Spoke
# --------------------------------------------------------------------------
# These variables parameterise the dev spoke deployment. Defaults are tuned
# for a lightweight development environment; override them via a .tfvars
# file or CLI flags for other scenarios.

# ---- General ----

variable "location" {
  description = "Azure region for all resources."
  type        = string
  default     = "eastus2"
}

variable "environment" {
  description = "Deployment environment (e.g. dev, staging, prod)."
  type        = string
  default     = "dev"
}

variable "workload_name" {
  description = "Short name for the workload. Used in the naming convention."
  type        = string
  default     = "foundry"
}

variable "instance" {
  description = "Instance number for resource naming (e.g. 001)."
  type        = string
  default     = "001"
}

# ---- Tagging ----

variable "owner" {
  description = "Team or individual responsible for this deployment."
  type        = string
  default     = "platform-team"
}

variable "cost_center" {
  description = "Cost-centre code for charge-back."
  type        = string
  default     = "cc-12345"
}

# ---- Networking ----

variable "address_space" {
  description = "CIDR blocks for the spoke virtual network."
  type        = list(string)
  default     = ["10.100.0.0/16"]
}

# ---- Observability ----

variable "log_analytics_sku" {
  description = "Pricing tier for the Log Analytics workspace."
  type        = string
  default     = "PerGB2018"
}

variable "log_analytics_retention_in_days" {
  description = "Number of days to retain logs (30–730)."
  type        = number
  default     = 30
}

# ---- Key Vault ----

variable "key_vault_sku" {
  description = "SKU for the Key Vault ('standard' or 'premium')."
  type        = string
  default     = "standard"
}
