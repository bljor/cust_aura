param networkSecurityGroupName string
param location string = resourceGroup().location

// Der skal findes en metode, så securityRules kan overføres via parametre. Og det skal være muligt at oprette
// mere end én securityRule i samme omgang.

// Network Security Group - bliver brugt af nedenstående virtualNetwork
resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2022-05-01' = {
  name: networkSecurityGroupName
  location: location
  properties: {
    securityRules: [
      {
        name: 'AllowRDPFromOfficePublicIP'
        properties: {
          priority: 100
          access: 'Allow'
          direction: 'Inbound'
          destinationPortRange: '3389'
          protocol: 'Tcp'
          sourcePortRange: '*'
          sourceAddressPrefixes: [
            '85.191.121.173/32','85.191.121.6/32'
          ]
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}
output networkSecurityGroupId string = networkSecurityGroup.id
