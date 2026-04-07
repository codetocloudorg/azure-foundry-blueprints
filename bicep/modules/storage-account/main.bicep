// Storage Account Module
// ----------------------
// Creates an Azure Storage Account for use as a data store by Azure AI Foundry
// and other platform services. Defaults to secure settings: HTTPS only,
// TLS 1.2, and public network access disabled.

// ---------------------
// Parameters
// ---------------------

@description('The name of the storage account. Must be globally unique (3–24 chars, lowercase alphanumeric).')
@minLength(3)
@maxLength(24)
param name string

@description('The Azure region where the storage account will be created.')
param location string

@description('The SKU name for the storage account.')
@allowed([
  'Standard_LRS'
  'Standard_GRS'
  'Standard_ZRS'
  'Standard_RAGRS'
  'Premium_LRS'
])
param skuName string = 'Standard_LRS'

@description('The kind of storage account.')
@allowed([
  'StorageV2'
  'BlobStorage'
])
param kind string = 'StorageV2'

@description('Whether public network access is enabled. Set to "Disabled" for private-only access.')
@allowed([
  'Enabled'
  'Disabled'
])
param publicNetworkAccess string = 'Disabled'

@description('A map of tags to apply to the storage account.')
param tags object = {}

// ---------------------
// Resources
// ---------------------

resource storageAccount 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: name
  location: location
  tags: tags
  kind: kind
  sku: {
    name: skuName
  }
  properties: {
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    publicNetworkAccess: publicNetworkAccess
  }
}

// ---------------------
// Outputs
// ---------------------

@description('The resource ID of the storage account.')
output id string = storageAccount.id

@description('The name of the storage account.')
output name string = storageAccount.name
