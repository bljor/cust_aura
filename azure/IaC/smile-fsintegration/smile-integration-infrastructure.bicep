// version pr. 04-06-2024 deployer uden fejl ...

var resourceGroupName = 'extbjo-sample-rg-d-dinel'
var storageAccountName = 'stfsintegdaura'
var recoveryServicesName = 'extbjo-recoveryservices'
var networkSecurityGroupName = 'smile-fsintegration-nsg-001-d-dinel'

var virtualNetworkName = 'smile-fsintegration-vnet-001-d-dinel'
var addressPrefix = '10.245.128.0/22'

targetScope = 'subscription'
resource newRG 'Microsoft.Resources/resourceGroups@2024-03-01' = {
  name: resourceGroupName
  location: 'westeurope'
}

module newStorageAccount '../bicep-modules/New-StorageAccount.bicep' = {
  name: 'storageModule'
  scope: newRG

  params: {
    location: newRG.location
    storageAccountName: storageAccountName
  }
}

module newRecoveryServicesVault '../bicep-modules/New-RecoveryServicesVault.bicep' = {
  name: 'recoveryServicesModule'
  scope: newRG
  
  params: {
    location: newRG.location
    rsvName: recoveryServicesName
  }
}

module newNetworkSecurityGroup '../bicep-modules/New-NetworkSecurityGroup.bicep' = {
  name: 'networkSecurityGroupModule'
  scope: newRG
  
  params: {
    location: newRG.location

    nsgRuleName: 'AllowRDPFromOfficePublicIP'
    networkSecurityGroupName: networkSecurityGroupName
    nsgPriority: 100
    nsgAccess: 'Allow'
    nsgDirection: 'Inbound'
    nsgDestinationPortRange: '3389'
    nsgProtocol: 'Tcp'
    nsgSourcePortRange: '*'
    nsgSourceAddressPrefixes: ['85.191.121.173/32','85.191.121.6/32']
    nsgDestinationAddressPrefix: '*'
  }
}

module newNetworkSecurityGroupRule2 '../bicep-modules/New-NetworkSecurityGroup.bicep' = {
  name: 'networkSecurityGroupRule2Module'
  scope: newRG

  params: {
    location: newRG.location

    nsgRuleName: 'AllowPort443-SSL'
    networkSecurityGroupName: networkSecurityGroupName
    nsgPriority: 101
    nsgAccess: 'Allow'
    nsgDirection: 'Inbound'
    nsgDestinationPortRange: '443'
    nsgProtocol: 'Tcp'
    nsgSourcePortRange: '*'
    nsgSourceAddressPrefixes: [
      '85.191.121.173/32','85.191.121.6/32'
    ]
    nsgDestinationAddressPrefix: '*'
  }
}

module newVirtualNetwork '../bicep-modules/New-VirtualNetwork.bicep' = {
  name: 'virtualNetwork'
  scope: newRG

  params: {
    virtualNetworkName: virtualNetworkName

    addressPrefix: addressPrefix
    subnetName: ''
    subnetPrefix: ''
    networkSecurityGroupId: newNetworkSecurityGroup.outputs.id
  }
}
