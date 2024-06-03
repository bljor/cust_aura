@description('Username for the Virtual Machine.')
param adminUsername string

@description('Password for the Virtual Machine.')
@minLength(12)
@secure()
param adminPassword string

//@description('Resource Group hvori ressourcer skal oprettes')
//param resourceGroupName string

@description('Deployment location')
param location string

var vmName = 'fs-integra1'
var securityType = 'TrustedLaunch'   // must be either TrustedLaunch or Standard
var vmSize = 'Standard_D2as_v5'

var tagCostCenter = 'Dinel'
var tagOpsTeam = 'IT-Drift'
var tagEnvironment = 'Dev'

var keyVaultName = 'smile-fsi-kv-d-dinel'
var recoveryVaultName = 'smile-fsi-rv-d-dinel'
var backupPolicyName = 'smile-fsi-backuppolicy-d-dinel'
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
var extensionName = 'AADLoginForWindows'
var extensionPublisher = 'Microsoft.Azure.ActiveDirectory'
var extensionVersion = '1.0'
var extensionType = 'AADLoginForWindows'

resource storageAccount 'Microsoft.Storage/storageAccounts@2022-05-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'Storage'
}

// Key Vault til opbevaring af certifikater og nøgler
resource keyvaultcerts 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: keyVaultName
  location: location
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

// Recovery Services Vault til lagring og opbevaring af backup, der konfigureres for virtuelle maskiner
resource recoveryServicesVault 'Microsoft.RecoveryServices/vaults@2022-01-01' = {
  name: recoveryVaultName
  location: location
  identity: {
    type: 'SystemAssigned'
  }
  sku: {
    name: 'RS0'
    tier: 'Standard'
  }
  properties: {}
}

// Backup Policy som styrer hvordan backup laves. Relateret til Recovery Services ovenfor
resource backupPolicy 'Microsoft.RecoveryServices/vaults/backupPolicies@2024-04-01' = {
  name: backupPolicyName
  location: location
  tags: {
    opsTeam: tagOpsTeam
    costCenter: tagCostCenter
    Environment: tagEnvironment    
  }

  parent: recoveryServicesVault
  properties: {
    backupManagementType: 'AzureIaasVM'
//    instantRpRetentionRangeInDays: 7
    policyType: 'V2'
//    tieringPolicy: {}
//    timeZone: 'UTC'

//    instantRPDetails: {
//      azureBackupRGNamePrefix: 'backup-prefix'
//      azureBackupRGNameSuffix: 'backup-suffix'
//    }

    retentionPolicy: {
      retentionPolicyType: 'SimpleRetentionPolicy'

      retentionDuration: {
        count: 7
        durationType: 'Days'
      }
    }

    schedulePolicy: {
      schedulePolicyType: 'SimpleSchedulePolicyV2'
      scheduleRunFrequency: 'Daily'
      dailySchedule: {
        scheduleRunTimes:  [
          '2024-06-03T19:00:00Z'
        ]
      }
    }

  }

}

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
            id: networkSecurityGroup.id
          }
        }
      }
    ]
  }
}

// Network Interface - relateret til ovenstående Virtual Network
resource nic 'Microsoft.Network/networkInterfaces@2022-05-01' = {
  name: nicName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'privateipconfig'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          privateIPAddressVersion: 'IPv4'
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

// Oprettelse af den virtuelle maskine, afhænger af ovenstående Network Interface
resource vm 'Microsoft.Compute/virtualMachines@2022-03-01' = {
  name: vmName
  location: location
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

// Konfiguration af automatisk slukning af VM hver aften kl. 19:00 UTC, er knyttet til ovenstående VM
resource autoShutdownConfig 'Microsoft.DevTestLab/schedules@2018-09-15' = {
  name: 'shutdown-computevm-${vmName}'
  location: location
  tags: {
    opsTeam: tagOpsTeam
    costCenter: tagCostCenter
    Environment: tagEnvironment
  }
  properties: {
    dailyRecurrence: {
      time: '1900'
    }
    notificationSettings: {
      status: 'Disabled'
    }
    status: 'Enabled'
    timeZoneId: 'UTC'
    taskType: 'ComputeVmShutdownTask'
    targetResourceId: vm.id
  }
}

// Extensions for den Virtuelle Maskine
resource vmExtension 'Microsoft.Compute/virtualMachines/extensions@2022-03-01' = if ((securityType == 'TrustedLaunch') && ((securityProfileJson.uefiSettings.secureBootEnabled == true) && (securityProfileJson.uefiSettings.vTpmEnabled == true))) {
  parent: vm
  name: extensionName
  location: location
  properties: {
    publisher: extensionPublisher
    type: extensionType
    typeHandlerVersion: extensionVersion
    autoUpgradeMinorVersion: true
  }
}

// Oprettelse af managed identity som giver adgang til at læse certifikater i key vault
resource managedidentity001 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: 'certreader-smile-fsintegration-kv-id-d-dinel'
  location: location
  tags: {
    costCenter: tagCostCenter
    opsTeam: tagOpsTeam
    Environment: tagEnvironment
  }
}

// Oprettelse af managed identity som giver adgang til at læse secrets i key vault
resource managedidentity002 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: 'secretreader-smile-fsintegration-kv-id-d-dinel'
  location: location
  tags: {
    costCenter: tagCostCenter
    opsTeam: tagOpsTeam
    Environment: tagEnvironment
  }
}

// Oprettelse af Route Tables, relateret til 
resource routetable001 'Microsoft.Network/routeTables@2023-11-01' = {
  name: 'smile-fsintegration-ft-hub-d-aura'
  location: location
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

// Oprettele af den første private DNS zone til dev.api.private.aura.dk
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

// Oprettelse af den anden private DNS zone til Container Registry
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

// Oprettelse af den tredje private DNS zone til Container Instances
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
