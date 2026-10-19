// ---------------------------------------------------------------------------
// Module: vnet.bicep
// Purpose: Deploys one Virtual Network with any number of subnets.
// Everything that can change between environments is a parameter, so the
// same file can be reused for dev, test or prod without editing the code.
// ---------------------------------------------------------------------------

@description('Azure region for the VNet (for example canadacentral).')
param location string

@description('Name of the Virtual Network.')
@minLength(2)
@maxLength(64)
param vnetName string

@description('Address space for the VNet in CIDR notation, e.g. 10.10.0.0/16.')
param addressPrefixes array

@description('Subnets to create. Each item needs a name and an addressPrefix.')
param subnets array

@description('Tags applied to the VNet.')
param tags object = {}

resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: vnetName
  location: location
  tags: tags
  properties: {
    addressSpace: {
      addressPrefixes: addressPrefixes
    }
    // A loop: one subnet object is generated for every item in the subnets parameter.
    subnets: [for subnet in subnets: {
      name: subnet.name
      properties: {
        addressPrefix: subnet.addressPrefix
      }
    }]
  }
}

@description('Resource ID of the VNet.')
output vnetId string = vnet.id

@description('Name of the VNet.')
output vnetName string = vnet.name

@description('Name and resource ID of every subnet created.')
output subnets array = [for (subnet, i) in subnets: {
  name: vnet.properties.subnets[i].name
  id: vnet.properties.subnets[i].id
  addressPrefix: subnet.addressPrefix
}]
