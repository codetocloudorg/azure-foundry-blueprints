// Microsoft Foundry Module (New Architecture)
// -------------------------------------------
// Creates a Microsoft Foundry resource using the NEW architecture based on
// Microsoft.CognitiveServices/accounts with kind "AIServices".
//
// IMPORTANT: This module sets `allowProjectManagement = true` which enables
// the NEW Foundry portal experience (not the classic hub-based approach).
//
// Reference: https://learn.microsoft.com/en-us/azure/ai-services/foundry/

// ---------------------
// Parameters
// ---------------------

@description('The name of the Microsoft Foundry resource (AI Services account).')
@minLength(2)
@maxLength(64)
param foundryName string

@description('The name of the Foundry project. Leave empty to skip project creation.')
param projectName string = ''

@description('Description for the Foundry project.')
param projectDescription string = 'Development project'

@description('The Azure region where the Foundry resource will be created.')
param location string

@description('The SKU for the AI Services account (e.g., S0).')
@allowed([
  'S0'
])
param skuName string = 'S0'

@description('Custom subdomain name for the Foundry endpoint. Must be globally unique.')
@minLength(2)
@maxLength(64)
param customSubdomainName string

@description('A list of user-assigned managed identity resource IDs to attach.')
param identityIds array = []

@description('Whether public network access is enabled.')
@allowed([
  'Enabled'
  'Disabled'
])
param publicNetworkAccess string = 'Disabled'

@description('Disable API key authentication (use managed identity only).')
param disableLocalAuth bool = false

@description('A map of tags to apply to the Foundry resources.')
param tags object = {}

// ---------------------
// Variables
// ---------------------

// Build the userAssignedIdentities object dynamically
var userAssignedIdentities = reduce(identityIds, {}, (cur, id) => union(cur, { '${id}': {} }))

// Determine identity type based on whether user-assigned identities are provided
var identityType = length(identityIds) > 0 ? 'SystemAssigned, UserAssigned' : 'SystemAssigned'

// ---------------------
// Resources
// ---------------------

// Microsoft Foundry resource using the NEW Cognitive Services architecture.
// Setting allowProjectManagement = true enables the modern Foundry portal
// experience for building agents, evaluations, and AI applications.
//
// NOTE: The 'allowProjectManagement' property may not be in the Bicep schema yet,
// but it IS supported by the Azure Resource Manager API. This mirrors how
// Terraform's AzAPI provider works with schema_validation_enabled = false.
resource foundry 'Microsoft.CognitiveServices/accounts@2025-06-01' = {
  name: foundryName
  location: location
  kind: 'AIServices'
  tags: tags
  sku: {
    name: skuName
  }
  identity: {
    type: identityType
    userAssignedIdentities: length(identityIds) > 0 ? userAssignedIdentities : null
  }
  properties: {
    // Enable the NEW Foundry portal experience (not classic hub-based)
    // NOTE: This property may not be in the Bicep schema yet, but IS supported by ARM.
    #disable-next-line BCP037
    allowProjectManagement: true

    // Custom subdomain for DNS names created for this Foundry resource
    customSubDomainName: customSubdomainName

    // Network isolation — control public access for enterprise deployments
    publicNetworkAccess: publicNetworkAccess

    // Disable local auth if using managed identity only
    disableLocalAuth: disableLocalAuth
  }
}

// Foundry Project — development boundary inside the Foundry resource.
// Projects provide isolation for teams to build agents, evaluations, and AI apps.
// NOTE: This resource type may not have schema types available yet in Bicep.
#disable-next-line BCP081
resource project 'Microsoft.CognitiveServices/accounts/projects@2025-06-01' = if (!empty(projectName)) {
  parent: foundry
  name: projectName
  location: location
  tags: tags
  sku: {
    name: skuName
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    displayName: projectName
    description: projectDescription
  }
}

// ---------------------
// Outputs
// ---------------------

@description('The resource ID of the Microsoft Foundry resource.')
output id string = foundry.id

@description('The endpoint URL of the Microsoft Foundry resource.')
output endpoint string = 'https://${customSubdomainName}.cognitiveservices.azure.com/'

@description('The principal ID of the system-assigned managed identity.')
output principalId string = foundry.identity.principalId

@description('The resource ID of the Foundry project (if created).')
output projectId string = !empty(projectName) ? project.id : ''
