// Key Vault Module
// ----------------
// Creates an Azure Key Vault with RBAC-based authorization (no access policies),
// purge protection enabled, and public network access disabled by default.
// This follows enterprise security best practices for secret management.

// ---------------------
// Parameters
// ---------------------

@description('The name of the Key Vault. Must be globally unique (3–24 chars, alphanumeric and hyphens).')
@minLength(3)
@maxLength(24)
param name string

@description('The Azure region where the Key Vault will be created.')
param location string

@description('The Azure AD tenant ID for the Key Vault.')
param tenantId string

@description('The SKU of the Key Vault.')
@allowed([
  'standard'
  'premium'
])
param skuName string = 'standard'

@description('Whether public network access is enabled. Set to "Disabled" for private-only access.')
@allowed([
  'Enabled'
  'Disabled'
])
param publicNetworkAccess string = 'Disabled'

@description('A map of tags to apply to the Key Vault.')
param tags object = {}

// ---------------------
// Resources
// ---------------------

resource keyVault 'Microsoft.KeyVault/vaults@2024-04-01-preview' = {
  name: name
  location: location
  tags: tags
  properties: {
    tenantId: tenantId
    sku: {
      family: 'A'
      name: skuName
    }
    // Use Azure RBAC for access control instead of vault access policies.
    // This integrates with the platform's identity model and supports
    // conditional access, PIM, and audit logging natively.
    enableRbacAuthorization: true
    // Purge protection prevents permanent deletion of secrets during the
    // soft-delete retention period — required for enterprise compliance.
    enablePurgeProtection: true
    enableSoftDelete: true
    // Disable public access by default; access is through private endpoints only.
    publicNetworkAccess: publicNetworkAccess
  }
}

// ---------------------
// Outputs
// ---------------------

@description('The resource ID of the Key Vault.')
output id string = keyVault.id

@description('The URI of the Key Vault (e.g. https://<name>.vault.azure.net/).')
output vaultUri string = keyVault.properties.vaultUri

@description('The name of the Key Vault.')
output kvName string = keyVault.name
