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
  # Remote Backend (uncomment for shared / CI-CD workflows)
  # ---------------------------------------------------------
  # backend "azurerm" {
  #   resource_group_name  = "rg-terraform-state"
  #   storage_account_name = "stterraformstate"
  #   container_name       = "tfstate"
  #   key                  = "foundry-dev.tfstate"
  # }
}

provider "azurerm" {
  features {}

  # Use Azure AD for storage data plane operations (required when key-based auth is disabled)
  storage_use_azuread = true
}

provider "azapi" {
  # Uses same auth as azurerm by default
}
