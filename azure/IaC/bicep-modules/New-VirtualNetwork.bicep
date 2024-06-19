param virtualNetworkName string
param location string = resourceGroup().location

param addressPrefix string
param subnetName string
param subnetPrefix string
param networkSecurityGroupId string

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
        name: subnetName
        properties: {
          addressPrefix: subnetPrefix
          networkSecurityGroup: {
            id: networkSecurityGroupId
          }
        }
      }
    ]
  }
}
