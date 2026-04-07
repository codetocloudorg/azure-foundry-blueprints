// Azure AI Foundry Module
// -----------------------
// Creates an Azure AI Foundry hub and project using the
// Microsoft.MachineLearningServices/workspaces resource type.
// The hub (kind: 'hub') is the top-level workspace that aggregates
// shared resources; the project (kind: 'project') is a child workspace
// scoped for team or workload isolation.

// ---------------------
// Parameters
// ---------------------

@description('The name of the AI Foundry hub workspace.')
@minLength(2)
@maxLength(33)
param hubName string

@description('The name of the AI Foundry project workspace.')
@minLength(2)
@maxLength(33)
param projectName string

@description('The Azure region where the Foundry resources will be created.')
param location string

@description('The SKU name for both hub and project workspaces.')
@allowed([
  'Basic'
  'Standard'
])
param skuName string = 'Basic'

@description('The resource ID of the Key Vault associated with the hub.')
param keyVaultId string

@description('The resource ID of the Storage Account associated with the hub.')
param storageAccountId string

@description('The resource ID of the Application Insights instance associated with the hub.')
param applicationInsightsId string

@description('The resource ID of the user-assigned managed identity for the hub.')
param identityId string

@description('Whether public network access is enabled.')
@allowed([
  'Enabled'
  'Disabled'
])
param publicNetworkAccess string = 'Disabled'

@description('A map of tags to apply to the Foundry resources.')
param tags object = {}

// ---------------------
// Resources
// ---------------------

// The hub is the top-level AI Foundry workspace that aggregates shared
// resources (Key Vault, Storage, App Insights) and manages identity.
resource hub 'Microsoft.MachineLearningServices/workspaces@2024-10-01' = {
  name: hubName
  location: location
  kind: 'Hub'
  tags: tags
  sku: {
    name: skuName
    tier: skuName
  }
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${identityId}': {}
    }
  }
  properties: {
    friendlyName: hubName
    keyVault: keyVaultId
    storageAccount: storageAccountId
    applicationInsights: applicationInsightsId
    publicNetworkAccess: publicNetworkAccess
    primaryUserAssignedIdentity: identityId
  }
}

// The project is a child workspace scoped for team or workload isolation.
// It inherits shared resources from the parent hub.
resource project 'Microsoft.MachineLearningServices/workspaces@2024-10-01' = {
  name: projectName
  location: location
  kind: 'Project'
  tags: tags
  sku: {
    name: skuName
    tier: skuName
  }
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${identityId}': {}
    }
  }
  properties: {
    friendlyName: projectName
    hubResourceId: hub.id
    publicNetworkAccess: publicNetworkAccess
    primaryUserAssignedIdentity: identityId
  }
}

// ---------------------
// Outputs
// ---------------------

@description('The resource ID of the AI Foundry hub.')
output hubId string = hub.id

@description('The resource ID of the AI Foundry project.')
output projectId string = project.id
