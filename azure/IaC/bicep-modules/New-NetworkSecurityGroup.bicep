// Network Security Group - bliver brugt af nedenstående virtualNetwork
param location string = resourceGroup().location
param networkSecurityGroupName string

param nsgRuleName string                        //
param nsgPriority int                       //100
param nsgAccess string                      //'Allow '
param nsgDirection string                   //'Inbound'
param nsgDestinationPortRange string        //'3389'
param nsgProtocol string                    //'Tcp'
param nsgSourcePortRange string             //'*'
param nsgSourceAddressPrefixes array        //'85.191.121.173/32','85.191.121.6/32'
param nsgDestinationAddressPrefix string    //'*'


resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2022-05-01' = {
  name: networkSecurityGroupName
  location: location
  properties: {
    securityRules: [
      {
        name: nsgRuleName
        properties: {
          priority: nsgPriority
          access: nsgAccess
          direction: nsgDirection
          destinationPortRange: nsgDestinationPortRange
          protocol: nsgProtocol
          sourcePortRange: nsgSourcePortRange
          sourceAddressPrefixes: nsgSourceAddressPrefixes
          destinationAddressPrefix: nsgDestinationAddressPrefix
        }
      }
    ]
  }
}
output id string = networkSecurityGroup.id
