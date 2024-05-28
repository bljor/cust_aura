@description('Username for the Virtual Machine.')
param adminUsername string

@description('Password for the Virtual Machine.')
@minLength(12)
@secure()
param adminPassword string

@description('Unique DNS Name for the Public IP used to access the Virtual Machine.')
param dnsLabelPrefix string = toLower('${vmName}-${uniqueString(resourceGroup().id, vmName)}')

@description('Name for the Public IP used to access the Virtual Machine.')
param publicIpName string = 'smile-fsinteg1-01-pip-d-aura'

@description('Allocation method for the Public IP used to access the Virtual Machine.')
@allowed([
  'Dynamic'
  'Static'
])
param publicIPAllocationMethod string = 'Dynamic'

@description('SKU for the Public IP used to access the Virtual Machine.')
@allowed([
  'Basic'
  'Standard'
])
param publicIpSku string = 'Basic'

@description('Size of the virtual machine.')
param vmSize string = 'Standard_D2as_v5'

@description('Name of the virtual machine.')
param vmName string = 'fs-integra1'

@description('Security Type of the Virtual Machine.')
@allowed([
  'Standard'
  'TrustedLaunch'
])
param securityType string = 'TrustedLaunch'

var sharedLocation = resourceGroup().location

var tagCostCenter = 'Dinel'
var tagOpsTeam = 'IT-Drift'
var tagEnvironment = 'Dev'


var keyVaultName = 'smile-fsi-kv-d-dinel'
var storageAccountName = 'stfsintegdaura'
var nicName = 'fs-integra1-nic01'
var addressPrefix = '10.0.0.0/16'
var subnetName = 'Subnet'
var subnetPrefix = '10.0.0.0/24'
var virtualNetworkName = 'smile-fsintegration-vnet-001-d-dinel'
var networkSecurityGroupName = 'smile-fsintegration-nsg-001-d-dinel'
var securityProfileJson = {
  uefiSettings: {
    secureBootEnabled: true
    vTpmEnabled: true
  }
  securityType: securityType
}
var extensionName = 'GuestAttestation'
var extensionPublisher = 'Microsoft.Azure.Security.WindowsAttestation'
var extensionVersion = '1.0'
var maaTenantName = 'GuestAttestation'
var maaEndpoint = substring('emptyString', 0, 0)

resource storageAccount 'Microsoft.Storage/storageAccounts@2022-05-01' = {
  name: storageAccountName
  location: sharedLocation
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'Storage'
}

resource publicIp 'Microsoft.Network/publicIPAddresses@2022-05-01' = {
  name: publicIpName
  location: sharedLocation
  sku: {
    name: publicIpSku
  }
  properties: {
    publicIPAllocationMethod: publicIPAllocationMethod
    dnsSettings: {
      domainNameLabel: dnsLabelPrefix
    }
  }
}

resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2022-05-01' = {
  name: networkSecurityGroupName
  location: sharedLocation
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
          sourceAddressPrefix: '85.191.121.173,85.191.121.6'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2022-05-01' = {
  name: virtualNetworkName
  location: sharedLocation
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
            id: networkSecurityGroup.id
          }
        }
      }
    ]
  }
}

resource nic 'Microsoft.Network/networkInterfaces@2022-05-01' = {
  name: nicName
  location: sharedLocation
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIp.id
          }
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
  name: vmName
  location: sharedLocation
  properties: {
    hardwareProfile: {
      vmSize: vmSize
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
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: storageAccount.properties.primaryEndpoints.blob
      }
    }
    securityProfile: ((securityType == 'TrustedLaunch') ? securityProfileJson : null)
  }
}

resource vmExtension 'Microsoft.Compute/virtualMachines/extensions@2022-03-01' = if ((securityType == 'TrustedLaunch') && ((securityProfileJson.uefiSettings.secureBootEnabled == true) && (securityProfileJson.uefiSettings.vTpmEnabled == true))) {
  parent: vm
  name: extensionName
  location: sharedLocation
  properties: {
    publisher: extensionPublisher
    type: extensionName
    typeHandlerVersion: extensionVersion
    autoUpgradeMinorVersion: true
    enableAutomaticUpgrade: true
    settings: {
      AttestationConfig: {
        MaaSettings: {
          maaEndpoint: maaEndpoint
          maaTenantName: maaTenantName
        }
      }
    }
  }
}

resource keyvaultcerts 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: keyVaultName
  location: sharedLocation
  properties: {
    enabledForDeployment: false
    enabledForDiskEncryption: false
    enabledForTemplateDeployment: false
    tenantId: subscription().tenantId
    enableSoftDelete: true
    softDeleteRetentionInDays: 90
    accessPolicies: [
      {
        objectId: '8dc62288-6290-45de-8fa6-bfcf91eaa884'
        tenantId: subscription().tenantId
        permissions: {
          keys: [
            'list'
          ]          
          secrets: [
            'list'
          ] 
        }
      }
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

resource managedidentity001 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: 'certreader-smile-fsintegration-kv-id-d-dinel'
  location: sharedLocation
  tags: {
    costCenter: tagCostCenter
    opsTeam: tagOpsTeam
    Environment: tagEnvironment
  }
}

resource managedidentity002 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: 'secretreader-smile-fsintegration-kv-id-d-dinel'
  location: sharedLocation
  tags: {
    costCenter: tagCostCenter
    opsTeam: tagOpsTeam
    Environment: tagEnvironment
  }
}

resource routetable001 'Microsoft.Network/routeTables@2023-11-01' = {
  name: 'smile-fsintegration-ft-hub-d-aura'
  location: sharedLocation
  tags: {
    costCenter: tagCostCenter
    opsTeam: tagOpsTeam
    Environment: tagEnvironment
  }
  properties: {
    disableBgpRoutePropagation: true
    routes: [
      {
        id: 'route-id-0001'
        name: 'the-first-route'
        properties: {
          addressPrefix: '158.125.1.48/32'
          hasBgpOverride: false
          nextHopIpAddress: ''
          nextHopType: 'Internet'
        }
        type: 'string'
      }
    ]
  }
}


resource privDns01 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'dev.api.private.aura.dk'
  location: 'global'
  tags: {
    costCenter: tagCostCenter
    opsTeam: tagOpsTeam
    Environment: tagEnvironment
  }
  properties: {  }
}


resource privDns02 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.azurecr.io'
  location: 'global'
  tags: {
    costCenter: tagCostCenter
    opsTeam: tagOpsTeam
    Environment: tagEnvironment
  }
  properties: {  }
}

resource privDns03 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'proudmushroom-089bd104.westeurope.azcontainerapps.io'
  location: 'global'
  tags: {
    costCenter: tagCostCenter
    opsTeam: tagOpsTeam
    Environment: tagEnvironment
  }
  properties: {  }
}



output hostname string = publicIp.properties.dnsSettings.fqdn
