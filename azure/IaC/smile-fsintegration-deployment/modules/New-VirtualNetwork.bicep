param virtualNetworkName string
param location string = resourceGroup().location
param addressPrefix string
param networkSecurityGroupId string
param routeTableId string

// Virtual network - afhænger af Network Security Group defineret ovenfor
resource virtualNetwork 'Microsoft.Network/virtualNetworks@2022-05-01' = {
  name: virtualNetworkName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressPrefix
      ]
    }
    subnets: [
      {
        name: 'General-Purpose-subnet'
        properties: {
          addressPrefix: '10.245.128.0/24'
          networkSecurityGroup: {
            id: networkSecurityGroupId
          }
          routeTable: {
            id: routeTableId
          }
        }
      }
      {
        name: 'Container-App-Subnet'
        properties: {
          addressPrefix: '10.245.130.0/23'
          networkSecurityGroup: {
            id: networkSecurityGroupId
          }
          routeTable: {
            id: routeTableId
          }
        }
      }
      {
        name: 'LockedFor_AGW_VPNSNAT'
        properties: {
          addressPrefix: '10.245.129.240/28'
          networkSecurityGroup: {
            id: networkSecurityGroupId
          }
        }
      }
    ]
  }
}
output vnetID string = virtualNetwork.id
