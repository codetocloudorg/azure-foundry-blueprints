# =============================================================================
# Terraform Remote Backend Configuration
# =============================================================================
# This file configures Azure Storage as the remote state backend.
# 
# Usage:
#   terraform init -backend-config=backend.hcl
#
# For CI/CD pipelines, values are typically passed via environment variables
# or -backend-config CLI arguments.
#
# Prerequisites:
#   1. Storage account must exist (see scripts/bootstrap-backend.sh)
#   2. Caller must have "Storage Blob Data Contributor" role on the container
# =============================================================================

# Resource group containing the state storage account
resource_group_name = "rg-terraform-state"

# Storage account name (must be globally unique, 3-24 chars, lowercase alphanumeric)
storage_account_name = "stfoundrystate001"

# Blob container for state files
container_name = "tfstate"

# State file name (unique per deployment/environment)
key = "foundry-dev.tfstate"

# Use Azure AD authentication (recommended over access keys)
use_azuread_auth = true

# Enable OIDC for GitHub Actions (set via ARM_USE_OIDC env var in CI)
# use_oidc = true
