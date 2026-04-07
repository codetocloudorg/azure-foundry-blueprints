using './main.bicep'

// ---------------------
// Dev Environment Parameters
// ---------------------
// Deploy with:
//   az deployment sub create \
//     --location eastus2 \
//     --template-file ./main.bicep \
//     --parameters ./main.bicepparam

param location = 'eastus2'
param environment = 'dev'
param workloadName = 'foundry'

// Override defaults if needed:
// param instance = '001'
// param owner = 'platform-team'
// param costCenter = 'cc-12345'
