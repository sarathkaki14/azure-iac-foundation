// Parameter values for the DEV environment.
using '../main.bicep'

param environment = 'dev'
param workload = 'iacfnd'
param vnetAddressPrefix = '10.10.0.0/16'
param subnets = [
  {
    name: 'snet-web'
    addressPrefix: '10.10.1.0/24'
  }
  {
    name: 'snet-app'
    addressPrefix: '10.10.2.0/24'
  }
]
param owner = 'SK'
