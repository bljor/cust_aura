resource nic 'Microsoft.Network/networkInterfaces@2023-11-01' = {

  var virtualNetworkName = 'vnet-name'

  name: nicName
  location: resourceGroup().location
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
  
}
