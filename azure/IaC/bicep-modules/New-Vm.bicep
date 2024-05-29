@description('Brugernavn for administrator på den Virtuelle Maskine.')
param adminUsername string

@description('Administrator password til den Virtuelle Maskine.')
@minLength(12)
@secure()
param adminPassword string

@description('Lokation hvor alle ressourcer skal oprettes')
param commonLocation string = resourceGroup().location

@description('Navn på den Virtuelle Maskine')
param vmName string = 'extbjo-demovm1'

@description('Navn på Network Security Group')
param nsgName string = 'smile-fsintegration-nsg-001-d-dinel'

@description('Navn på det Virtuelle Netværk')
param vnetName string = 'extbjo-demo-vnet-001-d-dinel'

@description('Navn på det Network Interface der oprettes til den Virtuelle Maskine')
param vmNicName string = 'extbjo-demovm1-nic01'


// security profile til brug for VM
var securityProfileJson = {
  uefiSettings: {
    secureBootEnabled: true
    vTpmEnabled: true
  }
  securityType: 'TrustedLaunch'
}

param securityType string = 'TrustedLaunch'

// oprettelse af Network Security Group, opret kun én regel som tillader RDP fra Auras
// offentlinge IP adresser.
resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2022-05-01' = {
  name: nsgName
  location: commonLocation
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

// oprettelse af Virtual Network hvortil den Virtuelle Maskine bliver forbundet
resource virtualNetwork 'Microsoft.Network/virtualNetworks@2022-05-01' = {
  name: vnetName
  location: commonLocation
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'extbjo-demo-subnet-001-d-dinel'
        properties: {
          addressPrefix: '10.0.0.0/24'
          networkSecurityGroup: {
            id: networkSecurityGroup.id
          }
        }
      }
    ]
  }
}

// Oprettelse af Network Interface til den virtuelle maskine
resource nic 'Microsoft.Network/networkInterfaces@2022-05-01' = {
  name: vmNicName
  location: commonLocation
  properties: {
    ipConfigurations: [
      {
        name: 'privateipconfig'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          privateIPAddressVersion: 'IPv4'
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', 'extbjo-demo-vnet-001-d-dinel', 'extbjo-demo-subnet-001-d-dinel')
          }
        }
      }
    ]
  }
  dependsOn: [

    virtualNetwork
  ]
}

// oprettelse af den Virtuelle Maskine
resource vm 'Microsoft.Compute/virtualMachines@2022-03-01' = {
  name: vmName
  location: commonLocation
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_D2as_v4'    //'Standard_D2as_v5', 'Standard_B1ls'
      
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: 'microsoftwindowsdesktop'
        offer: 'windows-11'
        sku: 'win11-22h2-pro'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'StandardSSD_LRS'
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }

    securityProfile: ((securityType == 'TrustedLaunch') ? securityProfileJson : null)
  }
}
