@description('Username for the Virtual Machine.')
param adminUsername string

@description('Password for the Virtual Machine.')
@minLength(12)
@secure()
param adminPassword string


var securityProfileJson = {
  uefiSettings: {
    secureBootEnabled: true
    vTpmEnabled: true
  }
  securityType: 'TrustedLaunch'
}

resource nic 'Microsoft.Network/networkInterfaces@2022-05-01' = {
  name: 'extbjo-demovm1-nic01'
  location: 'westeurope'
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'

          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, subnetName)
          }
        }
      }
    ]
  }
  dependsOn: [

    virtualNetwork
  ]
}



resource vm 'Microsoft.Compute/virtualMachines@2022-03-01' = {
  name: 'extbjo-demovm1'
  location: 'westeurope'
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_D2as_v5'
    }
    osProfile: {
      computerName: 'extbjo-demovm1'
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
