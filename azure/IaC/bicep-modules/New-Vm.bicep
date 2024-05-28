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

param securityType string = 'TrustedLaunch'


resource kvsecrets 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: 'extbjo-keyvault-001'
  location: resourceGroup().location
  properties: {
    enabledForDeployment: false
    enabledForDiskEncryption: false
    enabledForTemplateDeployment: false
    tenantId: subscription().tenantId
    enableSoftDelete: true
    softDeleteRetentionInDays: 90
    accessPolicies: [

    ]
    sku: {
      name: 'standard'
      family: 'A'
    }
    networkAcls: {
      defaultAction: 'Allow'
      bypass: 'AzureServices'
    }
  }
}


resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2022-05-01' = {
  name: 'smile-fsintegration-nsg-001-d-dinel'
  location: resourceGroup().location
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

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2022-05-01' = {
  name: 'extbjo-demo-vnet-001-d-dinel'
  location: resourceGroup().location
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

resource nic 'Microsoft.Network/networkInterfaces@2022-05-01' = {
  name: 'extbjo-demovm1-nic01'
  location: resourceGroup().location
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



resource vm 'Microsoft.Compute/virtualMachines@2022-03-01' = {
  name: 'extbjo-demovm1'
  location: resourceGroup().location
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_D2as_v4'    //'Standard_D2as_v5', 'Standard_B1ls'
      
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
