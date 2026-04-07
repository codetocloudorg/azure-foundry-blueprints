// Application Insights Module
// ----------------------------
// Creates an Application Insights instance backed by a Log Analytics workspace.
// The workspace-based mode (v2) is required — classic mode is deprecated.
// This provides telemetry and APM for Azure Foundry and connected services.

// ---------------------
// Parameters
// ---------------------

@description('The name of the Application Insights resource.')
@minLength(1)
@maxLength(260)
param name string

@description('The Azure region where Application Insights will be created.')
param location string

@description('The type of application being monitored.')
@allowed([
  'web'
  'java'
  'other'
])
param applicationType string = 'web'

@description('The resource ID of the Log Analytics workspace that backs this instance.')
param workspaceId string

@description('A map of tags to apply to Application Insights.')
param tags object = {}

// ---------------------
// Resources
// ---------------------

resource appInsights 'Microsoft.Insights/components@2020-02-02' = {
  name: name
  location: location
  kind: applicationType
  tags: tags
  properties: {
    Application_Type: applicationType
    WorkspaceResourceId: workspaceId
  }
}

// ---------------------
// Outputs
// ---------------------

@description('The resource ID of the Application Insights instance.')
output id string = appInsights.id

@description('The instrumentation key used to connect telemetry producers.')
output instrumentationKey string = appInsights.properties.InstrumentationKey

@description('The connection string for Application Insights.')
output connectionString string = appInsights.properties.ConnectionString
