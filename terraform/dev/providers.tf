# --------------------------------------------------------------------------
# Provider Configuration
# --------------------------------------------------------------------------
# Configures the AzureRM provider for the dev spoke deployment.
# The backend block is commented out for local development — uncomment and
# configure when using remote state with Azure Storage.

terraform {
  required_version = ">= 1.5"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = ">= 4.0"
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
}
