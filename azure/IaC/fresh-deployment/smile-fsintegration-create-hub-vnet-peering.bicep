param peeringName string
param vnetName string
param localPrefix string
param remotePrefix string
param remoteVnetID string

var completePeeringName = '${vnetName}/${peeringName}'

resource peering 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2023-11-01' = {

  name: completePeeringName
  properties: {
    allowForwardedTraffic: true
    allowGatewayTransit: false
    allowVirtualNetworkAccess: true
    doNotVerifyRemoteGateways: false

    remoteAddressSpace: {
      addressPrefixes: [
        localPrefix
      ]
    }
    remoteVirtualNetwork: {
      id: remoteVnetID
    }
    remoteVirtualNetworkAddressSpace: {
      addressPrefixes: [
        remotePrefix
      ]
    }
  }
}
