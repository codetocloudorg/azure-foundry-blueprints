// ============================================================================
// Azure AI Foundry — Dev Spoke Deployment
// ============================================================================
// Orchestrates all modules to deploy a complete Azure AI Foundry dev spoke.
// Subscription-scoped so it can create the resource group, then deploys all
// resources into that group via module calls.
//
// Deployment order:
//   1. Resource Group
//   2. Networking (VNet, NSGs)
//   3. Observability (Log Analytics, Application Insights)
//   4. Identity (Managed Identity)
//   5. Data (Storage Account, Key Vault)
//   6. DNS (Private DNS Zones)
//   7. AI Foundry (Hub + Project)
//   8. Private Endpoints (Key Vault, Storage Blob, Storage File, AI Foundry Hub)
// ============================================================================

targetScope = 'subscription'

// ---------------------
// Parameters
// ---------------------

@description('The Azure region for all resources.')
param location string

@description('The environment name (e.g. dev, staging, prod).')
@allowed([
  'dev'
  'staging'
  'prod'
])
param environment string

@description('The workload name used in resource naming.')
param workloadName string

@description('The numeric instance identifier for uniqueness.')
param instance string = '001'

@description('The Azure AD tenant ID for Key Vault. Defaults to the current subscription tenant.')
param tenantId string = subscription().tenantId

@description('The owner team responsible for these resources.')
param owner string = 'platform-team'

@description('The cost center code for billing purposes.')
param costCenter string = 'cc-12345'

// ---------------------
// Variables — Naming Convention
// ---------------------
// Format: {resource-prefix}-{workload}-{environment}-{regionShort}-{instance}
// See: /shared/naming/README.md

var regionShortMap = {
  eastus: 'eus'
  eastus2: 'eus2'
  westus: 'wus'
  westus2: 'wus2'
  westus3: 'wus3'
  centralus: 'cus'
  northeurope: 'ne'
  westeurope: 'we'
  uksouth: 'uks'
  ukwest: 'ukw'
}

var regionShort = regionShortMap[location]
var nameSuffix = '${workloadName}-${environment}-${regionShort}-${instance}'

// Resource names following the shared naming convention
var rgName = 'rg-${nameSuffix}'
var vnetName = 'vnet-${nameSuffix}'
var logName = 'log-${nameSuffix}'
var appiName = 'appi-${nameSuffix}'
var kvName = 'kv-${nameSuffix}'
var idName = 'id-${nameSuffix}'
var hubName = 'aihub-${nameSuffix}'
var projName = 'aiproj-${nameSuffix}'

// Storage accounts: lowercase alphanumeric only, no hyphens (3–24 chars)
var stName = 'st${workloadName}${environment}${regionShort}${instance}'

// ---------------------
// Variables — Tags
// ---------------------

var commonTags = {
  environment: environment
  workload: workloadName
  owner: owner
  'cost-center': costCenter
  'managed-by': 'bicep'
}

// ---------------------
// Variables — Networking
// ---------------------
// See: /shared/network-design/README.md

var vnetAddressSpace = '10.100.0.0/16'

var subnets = [
  {
    name: 'snet-default'
    addressPrefix: '10.100.0.0/24'
  }
  {
    name: 'snet-pe'
    addressPrefix: '10.100.1.0/24'
    // Disable network policies so private endpoint NICs can be placed here.
    privateEndpointNetworkPolicies: 'Disabled'
  }
  {
    name: 'snet-ai'
    addressPrefix: '10.100.2.0/24'
  }
  {
    name: 'snet-management'
    addressPrefix: '10.100.3.0/24'
  }
]

// Private DNS zones required for private endpoint FQDN resolution.
// Each zone enables in-VNet name resolution for its corresponding private endpoint.
//
// Index  0: Azure ML API          — AI Foundry Hub workspace control-plane
// Index  1: Azure ML Notebooks    — AI Foundry compute instances & notebooks
// Index  2: Cognitive Services     — Cognitive Services accounts
// Index  3: Azure OpenAI           — Azure OpenAI model endpoints
// Index  4: AI Services            — Unified AI Services endpoint
// Index  5: Key Vault              — Secret, key, and certificate access
// Index  6: Blob Storage           — Storage account blob data
// Index  7: File Storage           — SMB file shares used by AI Foundry
// Index  8: Azure Monitor          — Metrics and diagnostics
// Index  9: Log Analytics (ODS)    — Data ingestion for Log Analytics
// Index 10: Log Analytics (OMS)    — OMS agent communication
// Index 11: Automation             — Azure Automation hybrid worker agent
var privateDnsZoneNames = [
  'privatelink.api.azureml.ms'
  'privatelink.notebooks.azure.net'
  'privatelink.cognitiveservices.azure.com'
  'privatelink.openai.azure.com'
  'privatelink.aiservices.azure.com'
  'privatelink.vaultcore.azure.net'
  #disable-next-line no-hardcoded-env-urls // DNS zone name, not an endpoint URL
  'privatelink.blob.core.windows.net'
  #disable-next-line no-hardcoded-env-urls // DNS zone name, not an endpoint URL
  'privatelink.file.core.windows.net'
  'privatelink.monitor.azure.com'
  'privatelink.ods.opinsights.azure.com'
  'privatelink.oms.opinsights.azure.com'
  'privatelink.agentsvc.azure-automation.net'
]

// ============================
// 1. Resource Group
// ============================

resource rg 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: rgName
  location: location
  tags: commonTags
}

// ============================
// 2a. Networking — Virtual Network + Subnets
// ============================

module vnet '../modules/vnet/main.bicep' = {
  name: 'vnetDeploy'
  scope: rg
  params: {
    name: vnetName
    location: location
    addressPrefixes: [vnetAddressSpace]
    subnets: subnets
    tags: commonTags
  }
}

// ============================
// 2b. Networking — Network Security Groups (one per subnet)
// ============================

module nsgDefault '../modules/nsg/main.bicep' = {
  name: 'nsgDefaultDeploy'
  scope: rg
  dependsOn: [vnet]
  params: {
    name: 'nsg-default-${nameSuffix}'
    location: location
    tags: commonTags
  }
}

module nsgPe '../modules/nsg/main.bicep' = {
  name: 'nsgPeDeploy'
  scope: rg
  dependsOn: [vnet]
  params: {
    name: 'nsg-pe-${nameSuffix}'
    location: location
    tags: commonTags
  }
}

module nsgAi '../modules/nsg/main.bicep' = {
  name: 'nsgAiDeploy'
  scope: rg
  dependsOn: [vnet]
  params: {
    name: 'nsg-ai-${nameSuffix}'
    location: location
    tags: commonTags
  }
}

module nsgManagement '../modules/nsg/main.bicep' = {
  name: 'nsgManagementDeploy'
  scope: rg
  dependsOn: [vnet]
  params: {
    name: 'nsg-mgmt-${nameSuffix}'
    location: location
    tags: commonTags
  }
}

// ============================
// 3a. Observability — Log Analytics Workspace
// ============================

module logAnalytics '../modules/log-analytics/main.bicep' = {
  name: 'logAnalyticsDeploy'
  scope: rg
  params: {
    name: logName
    location: location
    sku: 'PerGB2018'
    retentionInDays: 30
    tags: commonTags
  }
}

// ============================
// 3b. Observability — Application Insights
// ============================

module appInsights '../modules/app-insights/main.bicep' = {
  name: 'appInsightsDeploy'
  scope: rg
  params: {
    name: appiName
    location: location
    applicationType: 'web'
    workspaceId: logAnalytics.outputs.id
    tags: commonTags
  }
}

// ============================
// 4. Identity — User-Assigned Managed Identity
// ============================

module managedIdentity '../modules/managed-identity/main.bicep' = {
  name: 'managedIdentityDeploy'
  scope: rg
  params: {
    name: idName
    location: location
    tags: commonTags
  }
}

// ============================
// 5a. Data — Storage Account (required by AI Foundry)
// ============================

module storageAccount '../modules/storage-account/main.bicep' = {
  name: 'storageAccountDeploy'
  scope: rg
  params: {
    name: stName
    location: location
    tags: commonTags
  }
}

// ============================
// 5b. Security — Key Vault
// ============================

module keyVault '../modules/key-vault/main.bicep' = {
  name: 'keyVaultDeploy'
  scope: rg
  params: {
    name: kvName
    location: location
    tenantId: tenantId
    skuName: 'standard'
    publicNetworkAccess: 'Disabled'
    tags: commonTags
  }
}

// ============================
// 6. Private DNS Zones
// ============================
// Each zone is linked to the VNet so private endpoint FQDNs resolve
// to their private IPs within the network.

module privateDns '../modules/private-dns/main.bicep' = [
  for (zone, i) in privateDnsZoneNames: {
    name: 'privateDns-${replace(zone, '.', '-')}'
    scope: rg
    params: {
      name: zone
      virtualNetworkId: vnet.outputs.id
      tags: commonTags
    }
  }
]

// ============================
// 7. AI Foundry — Hub + Project
// ============================
// Uses the new Cognitive Services-based architecture with allowProjectManagement.
// No longer requires Key Vault, Storage, or App Insights linked resources.

module foundry '../modules/foundry/main.bicep' = {
  name: 'foundryDeploy'
  scope: rg
  params: {
    foundryName: hubName
    projectName: projName
    projectDescription: 'Development project for ${workloadName}'
    location: location
    skuName: 'S0'
    customSubdomainName: 'foundry-${workloadName}-${environment}-${regionShort}-${instance}'
    identityIds: [managedIdentity.outputs.id]
    publicNetworkAccess: 'Disabled'
    disableLocalAuth: false
    tags: commonTags
  }
}

// ============================
// 8a. Private Endpoint — Key Vault
// ============================
// Ensures secret/key/certificate access from AI Foundry stays on the VNet.

module peKeyVault '../modules/private-endpoint/main.bicep' = {
  name: 'peKeyVaultDeploy'
  scope: rg
  params: {
    name: 'pep-kv-${nameSuffix}'
    location: location
    subnetId: vnet.outputs.subnetIds['snet-pe']
    privateLinkServiceId: keyVault.outputs.id
    groupIds: ['vault']
    privateDnsZoneIds: [
      privateDns[5].outputs.id // privatelink.vaultcore.azure.net
    ]
    tags: commonTags
  }
}

// ============================
// 8b. Private Endpoint — Storage Account (Blob)
// ============================
// AI Foundry stores model artifacts, datasets, and logs in blob storage.
// A blob PE keeps this traffic on the private network.

module peStorageBlob '../modules/private-endpoint/main.bicep' = {
  name: 'peStorageBlobDeploy'
  scope: rg
  params: {
    name: 'pep-st-blob-${nameSuffix}'
    location: location
    subnetId: vnet.outputs.subnetIds['snet-pe']
    privateLinkServiceId: storageAccount.outputs.id
    groupIds: ['blob']
    privateDnsZoneIds: [
      privateDns[6].outputs.id // privatelink.blob.core.windows.net
    ]
    tags: commonTags
  }
}

// ============================
// 8c. Private Endpoint — Storage Account (File)
// ============================
// AI Foundry mounts SMB file shares for code snapshots, prompt flow state,
// and compute instance home directories. The file PE prevents public egress.

module peStorageFile '../modules/private-endpoint/main.bicep' = {
  name: 'peStorageFileDeploy'
  scope: rg
  params: {
    name: 'pep-st-file-${nameSuffix}'
    location: location
    subnetId: vnet.outputs.subnetIds['snet-pe']
    privateLinkServiceId: storageAccount.outputs.id
    groupIds: ['file']
    privateDnsZoneIds: [
      privateDns[7].outputs.id // privatelink.file.core.windows.net
    ]
    tags: commonTags
  }
}

// ============================
// 8d. Private Endpoint — AI Foundry Hub
// ============================
// The Hub workspace PE requires multiple DNS zones because the Foundry
// control-plane, notebook compute, and backing AI services each resolve
// through different FQDNs. Registering all five zones ensures every
// request path stays on the private network.
// NOTE: Uses 'account' groupId for Cognitive Services (not 'amlworkspace').

module peFoundry '../modules/private-endpoint/main.bicep' = {
  name: 'peFoundryDeploy'
  scope: rg
  params: {
    name: 'pep-foundry-${nameSuffix}'
    location: location
    subnetId: vnet.outputs.subnetIds['snet-pe']
    privateLinkServiceId: foundry.outputs.id
    groupIds: ['account']
    privateDnsZoneIds: [
      privateDns[2].outputs.id // privatelink.cognitiveservices.azure.com — Cognitive Services
      privateDns[3].outputs.id // privatelink.openai.azure.com         — Azure OpenAI
      privateDns[4].outputs.id // privatelink.aiservices.azure.com     — AI Services
    ]
    tags: commonTags
  }
}

// ---------------------
// Outputs
// ---------------------

@description('The name of the deployed resource group.')
output resourceGroupName string = rg.name

@description('The resource ID of the virtual network.')
output vnetId string = vnet.outputs.id

@description('The Key Vault URI for secret access.')
output keyVaultUri string = keyVault.outputs.vaultUri

@description('The resource ID of the Microsoft Foundry resource.')
output foundryId string = foundry.outputs.id

@description('The endpoint URL of the Microsoft Foundry resource.')
output foundryEndpoint string = foundry.outputs.endpoint

@description('The resource ID of the Foundry project.')
output foundryProjectId string = foundry.outputs.projectId

@description('The Log Analytics workspace customer ID.')
output logAnalyticsWorkspaceId string = logAnalytics.outputs.workspaceId

@description('The Application Insights connection string for telemetry.')
output appInsightsConnectionString string = appInsights.outputs.connectionString
