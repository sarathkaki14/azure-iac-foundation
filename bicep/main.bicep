// ---------------------------------------------------------------------------
// main.bicep - entry point for the network foundation.
// Scope: resource group (the resource group is created first with Azure CLI).
// It builds standard names and tags from a few inputs, then calls the VNet module.
// ---------------------------------------------------------------------------
targetScope = 'resourceGroup'

@description('Environment short name. Drives resource names and tags.')
@allowed([
  'dev'
  'test'
])
param environment string = 'dev'

@description('Azure region. Defaults to the region of the target resource group.')
param location string = resourceGroup().location

@description('Short workload or project name used in resource names.')
@maxLength(10)
param workload string = 'iacfnd'

@description('Address space for the VNet.')
param vnetAddressPrefix string = '10.10.0.0/16'

@description('Subnets to create inside the VNet.')
param subnets array = [
  {
    name: 'snet-web'
    addressPrefix: '10.10.1.0/24'
  }
  {
    name: 'snet-app'
    addressPrefix: '10.10.2.0/24'
  }
]

@description('Person or team that owns these resources.')
param owner string = 'SK'

// Names and tags are calculated once here so every resource stays consistent.
var vnetName = 'vnet-${workload}-${environment}'
var commonTags = {
  environment: environment
  owner: owner
  project: 'Module4-IaC'
  deployedBy: 'Bicep'
}

module network 'modules/vnet.bicep' = {
  name: 'deploy-${vnetName}'
  params: {
    location: location
    vnetName: vnetName
    addressPrefixes: [
      vnetAddressPrefix
    ]
    subnets: subnets
    tags: commonTags
  }
}

// Outputs appear in the CLI result and in the portal under Deployments > Outputs.
output vnetName string = network.outputs.vnetName
output vnetId string = network.outputs.vnetId
output subnets array = network.outputs.subnets
output environment string = environment
