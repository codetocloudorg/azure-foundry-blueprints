# --------------------------------------------------------------------------
# Dev Environment — Variable Overrides
# --------------------------------------------------------------------------
# Usage: terraform plan -var-file="dev.tfvars"

location      = "eastus2"
environment   = "dev"
workload_name = "foundry"
instance      = "001"

# Tagging
owner       = "platform-team"
cost_center = "cc-12345"

# Networking
address_space = ["10.100.0.0/16"]

# Observability
log_analytics_sku               = "PerGB2018"
log_analytics_retention_in_days = 30

# Key Vault
key_vault_sku = "standard"
