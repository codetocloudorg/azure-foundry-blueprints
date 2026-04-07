#!/usr/bin/env bash
# =============================================================================
# Bootstrap Terraform Remote Backend
# =============================================================================
# Creates the Azure Storage account and container for Terraform state.
# Run this ONCE before using remote backend.
#
# Usage:
#   ./scripts/bootstrap-backend.sh [location] [storage_account_name]
#
# Defaults:
#   Location: westus2
#   Storage Account: stfoundrystate001
#
# Prerequisites:
#   - Azure CLI installed and logged in
#   - Contributor role on subscription
# =============================================================================

set -euo pipefail

# Configuration
LOCATION="${1:-westus2}"
STORAGE_ACCOUNT="${2:-stfoundrystate001}"
RESOURCE_GROUP="rg-terraform-state"
CONTAINER_NAME="tfstate"

echo "=== Terraform Backend Bootstrap ==="
echo "Location:        $LOCATION"
echo "Resource Group:  $RESOURCE_GROUP"
echo "Storage Account: $STORAGE_ACCOUNT"
echo "Container:       $CONTAINER_NAME"
echo ""

# Create resource group
echo "Creating resource group..."
az group create \
  --name "$RESOURCE_GROUP" \
  --location "$LOCATION" \
  --tags purpose=terraform-state managed-by=bootstrap-script

# Create storage account
echo "Creating storage account..."
az storage account create \
  --name "$STORAGE_ACCOUNT" \
  --resource-group "$RESOURCE_GROUP" \
  --location "$LOCATION" \
  --sku Standard_LRS \
  --kind StorageV2 \
  --min-tls-version TLS1_2 \
  --allow-blob-public-access false \
  --default-action Deny \
  --https-only true \
  --allow-shared-key-access false \
  --tags purpose=terraform-state managed-by=bootstrap-script

# Enable versioning for state recovery
echo "Enabling blob versioning..."
az storage account blob-service-properties update \
  --account-name "$STORAGE_ACCOUNT" \
  --resource-group "$RESOURCE_GROUP" \
  --enable-versioning true

# Create container
echo "Creating state container..."
az storage container create \
  --name "$CONTAINER_NAME" \
  --account-name "$STORAGE_ACCOUNT" \
  --auth-mode login

# Get current user principal ID
CURRENT_USER=$(az ad signed-in-user show --query id -o tsv 2>/dev/null || echo "")

if [[ -n "$CURRENT_USER" ]]; then
  echo "Assigning Storage Blob Data Contributor role to current user..."
  STORAGE_ID=$(az storage account show \
    --name "$STORAGE_ACCOUNT" \
    --resource-group "$RESOURCE_GROUP" \
    --query id -o tsv)
  
  az role assignment create \
    --role "Storage Blob Data Contributor" \
    --assignee "$CURRENT_USER" \
    --scope "$STORAGE_ID" 2>/dev/null || echo "Role already assigned or insufficient permissions"
fi

echo ""
echo "=== Bootstrap Complete ==="
echo ""
echo "Update your backend.hcl or use these values:"
echo ""
echo "  resource_group_name  = \"$RESOURCE_GROUP\""
echo "  storage_account_name = \"$STORAGE_ACCOUNT\""
echo "  container_name       = \"$CONTAINER_NAME\""
echo "  key                  = \"foundry-dev.tfstate\""
echo ""
echo "Initialize Terraform with:"
echo "  terraform init -backend-config=backend.hcl"
echo ""
echo "For GitHub Actions, add these repository variables:"
echo "  TF_STATE_RESOURCE_GROUP  = $RESOURCE_GROUP"
echo "  TF_STATE_STORAGE_ACCOUNT = $STORAGE_ACCOUNT"
echo "  TF_STATE_CONTAINER       = $CONTAINER_NAME"
