#!/usr/bin/env bash
#
# setup-azure.sh — Bootstrap script for Azure Foundry Blueprints
#
# This script:
#   1. Verifies required CLI tools are installed (az, terraform, bicep)
#   2. Logs into Azure interactively
#   3. Creates a resource group and storage account for Terraform remote state
#   4. Registers required Azure resource providers
#
# Usage:
#   ./scripts/bootstrap/setup-azure.sh
#
# Environment variables (optional overrides):
#   STATE_RESOURCE_GROUP  — Resource group for Terraform state (default: rg-tfstate)
#   STATE_STORAGE_ACCOUNT — Storage account name (default: stfoundrystate<random>)
#   STATE_CONTAINER       — Blob container name (default: tfstate)
#   LOCATION              — Azure region (default: eastus2)
#

set -euo pipefail

# ---------------------------------------------------------------------------
# Configuration — override via environment variables if needed
# ---------------------------------------------------------------------------
STATE_RESOURCE_GROUP="${STATE_RESOURCE_GROUP:-rg-tfstate}"
STATE_STORAGE_ACCOUNT="${STATE_STORAGE_ACCOUNT:-stfoundrystate${RANDOM}}"
STATE_CONTAINER="${STATE_CONTAINER:-tfstate}"
LOCATION="${LOCATION:-eastus2}"

# Resource providers required by Azure AI Foundry blueprints
REQUIRED_PROVIDERS=(
  "Microsoft.CognitiveServices"
  "Microsoft.MachineLearningServices"
  "Microsoft.KeyVault"
  "Microsoft.Storage"
  "Microsoft.Network"
  "Microsoft.ManagedIdentity"
  "Microsoft.Insights"
  "Microsoft.OperationalInsights"
)

# ---------------------------------------------------------------------------
# Helper functions
# ---------------------------------------------------------------------------
info()  { echo -e "\033[1;34m[INFO]\033[0m  $*"; }
ok()    { echo -e "\033[1;32m[OK]\033[0m    $*"; }
warn()  { echo -e "\033[1;33m[WARN]\033[0m  $*"; }
error() { echo -e "\033[1;31m[ERROR]\033[0m $*"; exit 1; }

check_command() {
  if ! command -v "$1" &>/dev/null; then
    error "'$1' is not installed. Please install it before running this script."
  fi
  ok "'$1' found: $(command -v "$1")"
}

# ---------------------------------------------------------------------------
# Step 1 — Check prerequisites
# ---------------------------------------------------------------------------
echo ""
info "============================================="
info "  Azure Foundry Blueprints — Bootstrap Setup"
info "============================================="
echo ""

info "Checking required CLI tools..."

check_command "az"
check_command "terraform"

# Bicep can be a standalone CLI or an az CLI extension
if command -v bicep &>/dev/null; then
  ok "'bicep' found: $(command -v bicep)"
elif az bicep version &>/dev/null; then
  ok "'bicep' available via az CLI extension"
else
  warn "'bicep' not found. Installing via az CLI..."
  az bicep install
  ok "'bicep' installed via az CLI"
fi

echo ""

# ---------------------------------------------------------------------------
# Step 2 — Azure login
# ---------------------------------------------------------------------------
info "Logging into Azure..."

# Check if already logged in
if az account show &>/dev/null; then
  CURRENT_ACCOUNT=$(az account show --query '[name, id]' -o tsv)
  info "Already logged in: ${CURRENT_ACCOUNT}"
  read -r -p "Use this account? [Y/n] " response
  if [[ "${response,,}" == "n" ]]; then
    az login
  fi
else
  az login
fi

SUBSCRIPTION_ID=$(az account show --query id -o tsv)
SUBSCRIPTION_NAME=$(az account show --query name -o tsv)
ok "Using subscription: ${SUBSCRIPTION_NAME} (${SUBSCRIPTION_ID})"
echo ""

# ---------------------------------------------------------------------------
# Step 3 — Register required resource providers
# ---------------------------------------------------------------------------
info "Registering required Azure resource providers..."

for provider in "${REQUIRED_PROVIDERS[@]}"; do
  STATE=$(az provider show --namespace "$provider" --query "registrationState" -o tsv 2>/dev/null || echo "NotRegistered")
  if [[ "$STATE" == "Registered" ]]; then
    ok "${provider} — already registered"
  else
    info "Registering ${provider}..."
    az provider register --namespace "$provider" --wait
    ok "${provider} — registered"
  fi
done

echo ""

# ---------------------------------------------------------------------------
# Step 4 — Create Terraform remote state storage
# ---------------------------------------------------------------------------
info "Setting up Terraform remote state storage..."
info "  Resource Group:   ${STATE_RESOURCE_GROUP}"
info "  Storage Account:  ${STATE_STORAGE_ACCOUNT}"
info "  Container:        ${STATE_CONTAINER}"
info "  Location:         ${LOCATION}"
echo ""

# Create resource group
info "Creating resource group '${STATE_RESOURCE_GROUP}'..."
az group create \
  --name "${STATE_RESOURCE_GROUP}" \
  --location "${LOCATION}" \
  --output none
ok "Resource group '${STATE_RESOURCE_GROUP}' ready"

# Create storage account
info "Creating storage account '${STATE_STORAGE_ACCOUNT}'..."
az storage account create \
  --name "${STATE_STORAGE_ACCOUNT}" \
  --resource-group "${STATE_RESOURCE_GROUP}" \
  --location "${LOCATION}" \
  --sku "Standard_LRS" \
  --kind "StorageV2" \
  --min-tls-version "TLS1_2" \
  --allow-blob-public-access false \
  --output none
ok "Storage account '${STATE_STORAGE_ACCOUNT}' ready"

# Create blob container for state files
info "Creating blob container '${STATE_CONTAINER}'..."
az storage container create \
  --name "${STATE_CONTAINER}" \
  --account-name "${STATE_STORAGE_ACCOUNT}" \
  --auth-mode login \
  --output none
ok "Blob container '${STATE_CONTAINER}' ready"

echo ""

# ---------------------------------------------------------------------------
# Done
# ---------------------------------------------------------------------------
info "============================================="
info "  Bootstrap complete!"
info "============================================="
echo ""
info "Terraform backend configuration:"
echo ""
echo "  terraform {"
echo "    backend \"azurerm\" {"
echo "      resource_group_name  = \"${STATE_RESOURCE_GROUP}\""
echo "      storage_account_name = \"${STATE_STORAGE_ACCOUNT}\""
echo "      container_name       = \"${STATE_CONTAINER}\""
echo "      key                  = \"foundry.tfstate\""
echo "    }"
echo "  }"
echo ""
