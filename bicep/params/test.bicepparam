// Parameter values for the TEST environment (optional extension task).
// Same template, different inputs: separate address range and an extra subnet.
using '../main.bicep'

param environment = 'test'
param workload = 'iacfnd'
param vnetAddressPrefix = '10.20.0.0/16'
param subnets = [
  {
    name: 'snet-web'
    addressPrefix: '10.20.1.0/24'
  }
  {
    name: 'snet-app'
    addressPrefix: '10.20.2.0/24'
  }
  {
    name: 'snet-data'
    addressPrefix: '10.20.3.0/24'
  }
]
param owner = 'SK'
