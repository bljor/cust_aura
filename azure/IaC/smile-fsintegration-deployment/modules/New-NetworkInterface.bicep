param nicName string
param location string = resourceGroup().location
param virtualNetworkName string
param virtualNetwork

// Network Interface - relateret til ovenstående Virtual Network
resource nic 'Microsoft.Network/networkInterfaces@2022-05-01' = {
  name: nicName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'privateipconfig'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          privateIPAddressVersion: 'IPv4'
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, 'General-Purpose-subnet')
          }
        }
      }
    ]
  }
  dependsOn: [
    virtualNetwork
  ]
}
