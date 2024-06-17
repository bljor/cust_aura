// version pr. 04-06-2024 deployer uden fejl ...

// TODO:
//
// Opgaver i fs-integration subscription
// -

// Opgaver i platform subscription
// - der skal laves firewall regler til fsintegration platformen
// - der skal laves ??


@description('Password for the Virtual Machine.')
@minLength(12)
@secure()
param adminPassword string



// Delte variable på tværs af ressourcer
var location = resourceGroup().location
var tagCostCenter = 'Dinel'
var tagOpsTeam = 'IT-Drift'
var tagEnvironment = 'Dev'


// Variabler til oprettelse af Network Security Group
var networkSecurityGroupName = 'smile-fsintegration-nsg-001-d-dinel'


// Variabler til oprettelse af VNET
var virtualNetworkName = 'smile-fsintegration-vnet-001-d-dinel'
var addressPrefix = '10.245.128.0/22'
var remotePrefix = '10.0.0.0/22'


// Variabler til Peering af VNet til HUb-vnet i Platform subscription


// Variabler til oprettelse af Network Interface Card (nic)
var nicName = 'fs-integra1-nic01'


// Variabler til oprettelse af VM
var vmName = 'fs-integra1'
var securityType = 'TrustedLaunch'          // skal være enten TrustedLaunch eller Standard
var vmSize = 'Standard_D2as_v5'             // Størrelse / opsætning på den VM der skal oprettes
var adminUsername = 'adminbjo'              // Navn på den admin-bruger konto der oprettes på VM'en
var securityProfileJson = {                 // Sikkerhedsprofil, der styrer Secure Boot og TPM chip
  uefiSettings: {
    secureBootEnabled: true
    vTpmEnabled: true
  }
  securityType: securityType
}
var extensionName = 'AADLoginForWindows'    // Definér extension til AAD login
var extensionPublisher = 'Microsoft.Azure.ActiveDirectory'
var extensionVersion = '1.0'
var extensionType = 'AADLoginForWindows'


// Variabler til oprettelse af Key Vault
var keyVaultName = 'smile-fsi-sub-kv-d-dinel'


// Variabler til oprettelse af Recovery Vault
var recoveryVaultName = 'smile-fsi-sub-rv-d-dinel'


// Variabler til oprettelse af backup policy
var backupPolicyName = 'smile-fsi-backuppolicy-d-dinel'


// Variabler til backup vault
var backupFabric = 'Azure'
var protectionContainer = 'iaasvmcontainer;iaasvmcontainerv2;${resourceGroup().name};${vmName}'
var protectedItem = 'vm;iaasvmcontainerv2;${resourceGroup().name};${vmName}'


// Variabler til oprettelse af Storage Account
var storageAccountName = 'stfsintegdaura'


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
  tags: {
    OpsTeam: 'IT-Drift'
    CostCenter: 'Dinel'
    Environment: 'Dev'
  }
  identity: {
    type: 'SystemAssigned'
  }
  sku: {
    name: 'RS0'
    tier: 'Standard'
  }
  properties: {}
}


// UDKOMMENTERET, FOR AT KUNNE SLETTE RECOVERY VAULT IGEN UDEN DER HÆNGER GAMLE DATA OG SPÆRRER FOR SLETNING
// Backup Policy som styrer hvordan backup laves. Relateret til Recovery Services ovenfor
resource backupPolicy 'Microsoft.RecoveryServices/vaults/backupPolicies@2022-04-01' = {

  name: backupPolicyName
  location: resourceGroup().location

  tags: {
    OpsTeam: 'IT-Drift'
    CostCenter: 'Dinel'
    Environment: 'Dev'
  }
  parent: recoveryServicesVault

  properties: {
    backupManagementType: 'AzureIaasVM'
    
    instantRPDetails: {
      azureBackupRGNamePrefix: null
      azureBackupRGNameSuffix: null
    }
    instantRpRetentionRangeInDays: 2
    policyType: 'V2'
    
    retentionPolicy: {
      retentionPolicyType: 'LongTermRetentionPolicy'
      dailySchedule: {
        retentionDuration: {
          count: 30
          durationType: 'Days'
        }
        retentionTimes: ['2024-06-04T19:00:00+00:00']
      }
      monthlySchedule: null
      weeklySchedule: null
      yearlySchedule: null
    }
    
    schedulePolicy: {
      dailySchedule: null
      hourlySchedule: {
        interval: 4
        scheduleWindowDuration: 12
        scheduleWindowStartTime: '2024-06-04T19:00:00+00:00'
      }
      schedulePolicyType: 'SimpleSchedulePolicyV2'
      scheduleRunFrequency: 'Hourly'
      weeklySchedule: null
    }
    timeZone: 'UTC'             // kunne måske også være 'Romance Standard Time'
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


// Virtual network - refererer til både Network Security Group defineret ovenfor,
// samt route table nedenfor
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
        name: 'General-Purpose-subnet'
        properties: {
          addressPrefix: '10.245.128.0/24'
          networkSecurityGroup: {
            id: networkSecurityGroup.id
          }
          routeTable: {
            id: routetable001.id
          }
        }
      }
      {
        name: 'Container-App-Subnet'
        properties: {
          addressPrefix: '10.245.130.0/23'
          networkSecurityGroup: {
            id: networkSecurityGroup.id
          }
          routeTable: {
            id: routetable001.id
          }
          delegations: [        // Skal udfyldes nedenfor ... denne del med delegations er ikke testet endnu
            {
              properties: {
                serviceName: 'Microsoft.App/environments'
              }
            }
          ]
        }
      }
      {
       name: 'LockedFor_AGW_VPNSNAT'
       properties: {
         addressPrefix: '10.245.129.240/28'
         networkSecurityGroup: {
           id: networkSecurityGroup.id
         }
       }
     }
    ]
  }
}
output vnetID string = virtualNetwork.id


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
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetworkName, 'General-Purpose-subnet')
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
  identity: {
    type: 'SystemAssigned'
  }
  tags: {
    Environment: tagEnvironment
    CostCenter: tagCostCenter
    OpsTeam: tagOpsTeam
  }
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
        sku: 'win11-23h2-pro'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'StandardSSD_LRS'
        }
        name: '${vmName}-osdisk01'
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
    timeZoneId: 'Romance Standard Time'             // kunne også være 'UTC'
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


// UDKOMMENTERET, FOR AT KUNNE SLETTE RECOVERY VAULT IGEN UDEN DER HÆNGER GAMLE DATA OG SPÆRRER FOR SLETNING
// Opret vault til lagring af
resource recoveryVaultName_backupFabric_protectionContainer_protectedItem 'Microsoft.RecoveryServices/vaults/backupFabrics/protectionContainers/protectedItems@2024-04-01' = {
  name: '${recoveryServicesVault.name}/${backupFabric}/${protectionContainer}/${protectedItem}'
  properties: {
    protectedItemType: 'Microsoft.Compute/virtualMachines'
    policyId: '${recoveryServicesVault.id}/backupPolicies/${backupPolicy.name}'
    sourceResourceId: vm.id
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
  name: 'dev.fs.api.private.aura.dk'
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


// Oprettelse af den tredje private DNS zone til Container Instances (navngivning skal sikkert ændres ift. de reelt oprettede
// container instances)
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


// Lavet som et module, for at kunne deploye til et andet subscription (ved oprettelse af peering02. Peering01 som oprettes, oprettes i
// smile-fsintegration-sub-nonproduction-dinel subscription (altså det aktulle subscription))
var hubVnetId = '/subscriptions/0d742875-267e-4db3-8a2b-10891ce92a5c/resourceGroups/platform-connectivity-rg/providers/Microsoft.Network/virtualNetworks/hub-vnet-001-p-aura'

module peering01 './smile-fsintegration-create-hub-vnet-peering.bicep' = {
  scope: resourceGroup()

  name: 'Peering-to-Hub-vnet'

  params: {
    peeringName: '${virtualNetwork.name}-To-Hub'
    vnetName: virtualNetwork.name
    localPrefix: addressPrefix
    remotePrefix: remotePrefix
    remoteVnetID: hubVnetId
  }
}


// Opret peering i Hub subscription
var hubVnetSubscriptionID = '0d742875-267e-4db3-8a2b-10891ce92a5c'
var hubVnetResourceGroup = 'platform-connectivity-rg'
var hubVnetName = 'hub-vnet-001-p-aura'

module peering02 './smile-fsintegration-create-hub-vnet-peering.bicep' = {
  name: 'Peering-From-Hub-vnet-to-${virtualNetwork.name}'
  scope: resourceGroup(hubVnetSubscriptionID, hubVnetResourceGroup)

  params: {
    peeringName: 'Hub-to-${virtualNetwork.name}'
    vnetName: hubVnetName
    localPrefix: remotePrefix
    remotePrefix: addressPrefix
    remoteVnetID: virtualNetwork.id
  }
}
