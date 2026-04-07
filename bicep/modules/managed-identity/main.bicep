// Managed Identity Module
// -----------------------
// Creates a user-assigned managed identity. This identity is used to
// authenticate Azure resources (e.g. Foundry, Key Vault) without secrets,
// following the principle of least privilege with RBAC role assignments.

// ---------------------
// Parameters
// ---------------------

@description('The name of the user-assigned managed identity.')
@minLength(3)
@maxLength(128)
param name string

@description('The Azure region where the identity will be created.')
param location string

@description('A map of tags to apply to the managed identity.')
param tags object = {}

// ---------------------
// Resources
// ---------------------

resource managedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: name
  location: location
  tags: tags
}

// ---------------------
// Outputs
// ---------------------

@description('The resource ID of the user-assigned managed identity.')
output id string = managedIdentity.id

@description('The principal (object) ID of the managed identity, used for RBAC role assignments.')
output principalId string = managedIdentity.properties.principalId

@description('The client (application) ID of the managed identity.')
output clientId string = managedIdentity.properties.clientId
