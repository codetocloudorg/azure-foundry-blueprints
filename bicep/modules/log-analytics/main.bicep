// Log Analytics Workspace Module
// --------------------------------
// Creates a Log Analytics workspace for centralized logging and monitoring.
// This workspace serves as the data sink for Application Insights and
// diagnostic settings across all resources in the spoke.

// ---------------------
// Parameters
// ---------------------

@description('The name of the Log Analytics workspace.')
@minLength(4)
@maxLength(63)
param name string

@description('The Azure region where the workspace will be created.')
param location string

@description('The SKU (pricing tier) for the workspace.')
@allowed([
  'Free'
  'PerGB2018'
  'PerNode'
  'Premium'
  'Standalone'
  'Standard'
])
param sku string = 'PerGB2018'

@description('The number of days to retain log data.')
@minValue(30)
@maxValue(730)
param retentionInDays int = 30

@description('A map of tags to apply to the workspace.')
param tags object = {}

// ---------------------
// Resources
// ---------------------

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: name
  location: location
  tags: tags
  properties: {
    sku: {
      name: sku
    }
    retentionInDays: retentionInDays
  }
}

// ---------------------
// Outputs
// ---------------------

@description('The resource ID of the Log Analytics workspace.')
output id string = logAnalytics.id

@description('The unique workspace ID (GUID) used for agent configuration and queries.')
output workspaceId string = logAnalytics.properties.customerId

@description('The unique customer ID (GUID) of the workspace, identical to workspaceId.')
output customerId string = logAnalytics.properties.customerId
