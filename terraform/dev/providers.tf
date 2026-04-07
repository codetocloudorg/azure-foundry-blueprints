# --------------------------------------------------------------------------
# Provider Configuration
# --------------------------------------------------------------------------
# Configures the AzureRM and AzAPI providers for the dev spoke deployment.
# AzAPI is required for the new Microsoft Foundry experience which uses
# properties not yet exposed in AzureRM (e.g., allowProjectManagement).

terraform {
  required_version = ">= 1.5"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.0"
    }
    azapi = {
      source  = "Azure/azapi"
      version = ">= 2.0"
    }
  }

  # ---------------------------------------------------------
  # Remote Backend — Azure Storage
  # ---------------------------------------------------------
  # For local development: terraform init -backend=false
  # For CI/CD or shared state: terraform init -backend-config=backend.hcl
  #
  # The backend block must be empty or have only static values.
  # Dynamic values are passed via -backend-config or env vars.
  # ---------------------------------------------------------
  backend "azurerm" {
    # Values provided via backend.hcl or CLI:
    #   resource_group_name  = "rg-terraform-state"
    #   storage_account_name = "stfoundrystate001"
    #   container_name       = "tfstate"
    #   key                  = "foundry-dev.tfstate"
    #   use_azuread_auth     = true
  }
}

provider "azurerm" {
  features {}

  # Use Azure AD for storage data plane operations (required when key-based auth is disabled)
  storage_use_azuread = true
}

provider "azapi" {
  # Uses same auth as azurerm by default
}
