using './main.bicep'

// ---------------------
// Dev Environment Parameters
// ---------------------
// Deploy with:
//   az deployment sub create \
//     --location westus2 \
//     --template-file ./main.bicep \
//     --parameters ./main.bicepparam

param location = 'westus2'
param environment = 'dev'
param workloadName = 'foundry'
param instance = '002'

// Override defaults if needed:
// param owner = 'platform-team'
// param costCenter = 'cc-12345'
