/*
    Hvad laves i denne deployment

    Følgende ressourcer oprettes:
    - Storage Account
    - Key Vault
    - Secret                                  (VM local admin users password)
    - Network Security Group
    - Route Table
    - Virtual Network
    - Subnet 1                                General Purpose subnet
    - Subnet 2                                Container subnet
    - Subnet 3                                AGW subnet
    - Network Interface                       for the VM
    - Virtual Machine
    - Disk                                    OS disk for the VM
    - Auto Shutdown Config                    for the VM
    - AAD Login extension                     for the VM
    - Assign user role                        for the developers to logon to the VM (VM User Login)
    - Assign admin role                       for administrators to logon to the VM (VM Admin Login)
    - Managed Identity                        for reading certificates from the Key Vault (granted Key Vault Certificates User role)
    - Managed Identity                        for reading secrets from the Key Vault (granted Key Vault Secrets Admin role)
    - Grant developers access                 developers group granted access to read certificates from the Key Vault (granted Key Vault Certificates User role)
    - Grant developers access                 developers group granted access to read secrets from the Key Vault (granted Key Vault Secrets User role)
    - Grant developers access                 developers group granted Contributor access to resource group for Container environment
    - Grant developers access                 developers group granted RBAC Admin access to resource group for Container environment
    - Private DNS zone                        for local DNS records
    - Create peering to hub vnet              Created in the new subscription
    - Create peering from the hub vnet        Created in the hub subscription
*/

// Hvad skal ændres inden deployment hos Aura
// vmSize
// 


@description('Password for the Virtual Machine.')
@minLength(12)
@secure()
param adminPassword string

@description('Resource Group to which Developers should be granted contributor + RBAC administrator roles')
param developersResourceGroup string

// Delte variable på tværs af ressourcer
var location = resourceGroup().location                    // location hvor ressourcer oprettes
var tagCostCenter = 'Dinel'
var tagOpsTeam = 'IT-Drift'
var tagEnvironment = 'Dev'

// Variabler til oprettelse af Network Security Group
var networkSecurityGroupName = 'smile-fsintegration-nsg-001-d-dinel'                  // modify this

// Variabler til oprettelse af VNET, subnets og peerings
var hubVnetAddressPrefix = '10.0.0.0/16'                                              // prefix for netværket i hub netværk, bruges til peering, ændres sjældent
var virtualNetworkName = 'smile-fsintegration-vnet-001-d-dinel'                       // modify this
var newVnewAddressPrefix = '10.245.128.0/22'                                          // modify this
var vnetSubnet1Name = 'General-Purpose-subnet'                                        // modify this
var vnetSubnet1AddressPrefix = '10.245.128.0/24'                                      // modify this
var vnetSubnet2Name = 'Container-App-Subnet'                                          // modify this
var vnetSubnet2AddressPrefix = '10.245.130.0/23'                                      // modify this
var vnetSubnet3Name = 'LockedFor_AGW_VPNSNAT'                                         // modify this
var vnetSubnet3AddressPrefix = '10.245.129.240/28'                                    // modify this


// Variabler til oprettelse af VM
var vmName = 'fs-integra1'                                                            // modify this
var securityType = 'TrustedLaunch'          // skal være enten TrustedLaunch eller Standard

// Variabler til oprettelse af Network Interface Card (nic)
var nicName = '${vmName}-nic01'

// Brug i wipe.dk                                                                     // modify this
var vmSize = 'Standard_B2s'

// Brug nedenstående hos Aura
// var vmSize = 'Standard_D2as_v5'             // Størrelse / opsætning på den VM der skal oprettes

var adminUsername = 'useradmin'              // Navn på den admin-bruger konto der oprettes på VM'en
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

var VmUserGroupId = 'a94dffa9-4bc6-495a-a91e-34a126024a84'              // ID of Entra ID group to grant Login User access to the VM
var VmAdminGroupId = '20ba48d0-9822-442e-9053-c3fca3546ead'             // ID of Entra ID group to grant Login Admin access to the VM

// Variabler til oprettelse af Key Vault
var keyVaultName = 'temp-wipedk-20240630-001'                                          // modify this

var roleKeyVaultCertUser = 'db79e9a7-68ee-4b58-9aeb-b90e7c24fcba'
var roleKeyVaultSecretUser = '4633458b-17de-408a-b874-0445c86b69e6'
var keyVaultDevelopersId = '35b37b21-57a3-4dbc-a047-4da7da12a477'       // ID of Entra ID group to grant Key Vault Secrets Users and Key Vault Cert Users access to the Key Vault

// Variabler til oprettelse af Storage Account

// Brug til wipe.dk
var storageAccountName = 'wipedktmp0001'                                               // modify this

// Brug hos Aura
//var storageAccountName = 'stfsintegdaura'

var mgIdentity001name = 'certreader-smile-fsintegration-kv-id-d-dinel'
var mgIdentity002name = 'secretreader-smile-fsintegration-kv-id-d-dinel'

var privDns01name = 'dev.api.aura.dk'


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
    enableRbacAuthorization: true
    tenantId: subscription().tenantId
    enableSoftDelete: true
    softDeleteRetentionInDays: 90
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

// Gem VM local admin username and password in the Key Vault
resource secret 'Microsoft.KeyVault/vaults/secrets@2023-07-01' = {
  parent: keyvaultcerts
  name: adminUsername
  properties: {
    value: adminPassword
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



// Oprettelse af Route Tables, relateret til 
resource routetable001 'Microsoft.Network/routeTables@2023-11-01' = {
  name: 'smile-fsintegration-ft-hub-d-dinel'
  location: location
  tags: {
    costCenter: tagCostCenter
    opsTeam: tagOpsTeam
    Environment: tagEnvironment
  }
  properties: {
    routes: [
      {
        name: 'the-first-route'
        properties: {
          addressPrefix: '158.125.1.48/32'
          hasBgpOverride: false
          nextHopIpAddress: ''
          nextHopType: 'Internet'
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
  tags : {
    costCenter: tagCostCenter
    opsTeam: tagOpsTeam
    Environment: tagEnvironment
  }
  properties: {
    addressSpace: {
    addressPrefixes: [
    newVnewAddressPrefix
      ]
    }
    subnets: [
      {
        name: vnetSubnet1Name
        properties: {
          addressPrefix: vnetSubnet1AddressPrefix
          networkSecurityGroup: {
            id: networkSecurityGroup.id
          }
          routeTable: {
            id: routetable001.id
          }
        }
      }
      {
        name: vnetSubnet2Name
        properties: {
          addressPrefix: vnetSubnet2AddressPrefix
          networkSecurityGroup: {
            id: networkSecurityGroup.id
          }
          routeTable: {
            id: routetable001.id
          }
          delegations: [
            {
              name: 'AppDelegations'
              properties: {
                serviceName: 'Microsoft.App/environments'
              }
            }
          ]
        }
      }
      {
       name: vnetSubnet3Name
       properties: {
         addressPrefix: vnetSubnet3AddressPrefix
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
  tags: {
    CostCenter: tagCostCenter
    opsTeam: tagOpsTeam
    Environment: tagEnvironment
  }
  properties: {
    ipConfigurations: [
      {
        name: 'privateipconfig'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          privateIPAddressVersion: 'IPv4'
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetwork.name, 'General-Purpose-subnet')
          }
        }
      }
    ]
  }
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
    ExceptionToPolicyRequireBackup: 'True'
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


// Tildel rettigheder til VM'en
// fb879df8-f326-4884-b1cf-06f3ad86be52     Virtual Machine User Login role
// 'a94dffa9-4bc6-495a-a91e-34a126024a84'   ID of the Entra ID group vmUsers

// 1c0163c0-47e6-4577-8991-ea5c82e286e4     Virtual Machine Administrator Login role
// '20ba48d0-9822-442e-9053-c3fca3546ead'   ID of the Entra ID group vmAdmins

resource roleAssignmentVMUser 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, vm.id, VmUserGroupId,'VirtualMachineUserLogin')
  scope: vm
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions','fb879df8-f326-4884-b1cf-06f3ad86be52')  // Virtual Machine User Login
    principalId: VmUserGroupId
    principalType: 'Group'
  }
}

resource roleAssignmentVMAdmin 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, vm.id, VmAdminGroupId,'VirtualMachineAdministratorLogin')
  scope: vm
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions','1c0163c0-47e6-4577-8991-ea5c82e286e4')  // Virtual Machine Administrator Login
    principalId: VmAdminGroupId
    principalType: 'Group'
  }
}

// Oprettelse af managed identity som skal have adgang til at læse certifikater i key vault
resource managedidentity001 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: mgIdentity001name
  location: location
  tags: {
    costCenter: tagCostCenter
    opsTeam: tagOpsTeam
    Environment: tagEnvironment
  }
}

// Give managed identity adgang til Key Vault som Key Vault Certificate User
resource roleAssignment001 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, keyvaultcerts.id, managedidentity001.id, 'KeyVaultCertificateUser')
  scope: keyvaultcerts
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', 'db79e9a7-68ee-4b58-9aeb-b90e7c24fcba') // Key Vault Certificate User
    principalId: managedidentity001.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

// Give developers access to Key Vault as Key Vault Certificate User
resource roleAssignment001b 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, keyvaultcerts.id, keyVaultDevelopersId, 'KeyVaultCertificateUser')
  scope: keyvaultcerts
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions',roleKeyVaultCertUser)
    principalId: keyVaultDevelopersId
    principalType: 'Group'
  }
}



// Oprettelse af managed identity som skal have adgang til at læse secrets i key vault
resource managedidentity002 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: mgIdentity002name
  location: location
  tags: {
    costCenter: tagCostCenter
    opsTeam: tagOpsTeam
    Environment: tagEnvironment
  }
}

// Giv managed identity 002 adgang til Key Vault
resource roleAssignment002 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, keyvaultcerts.id, managedidentity002.id, 'KeyVaultReader')
  scope: keyvaultcerts
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', roleKeyVaultSecretUser) // Key Vault Secrets User
    principalId: managedidentity002.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

// Give developers access to Key Vault as Key Vault Secrets User
resource roleAssignment002b 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(resourceGroup().id, keyvaultcerts.id, keyVaultDevelopersId, 'KeyVaultReader')
  scope: keyvaultcerts
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', roleKeyVaultSecretUser)
    principalId: keyVaultDevelopersId
    principalType: 'Group'
  }
}

var roleContributor = 'b24988ac-6180-42a0-ab88-20f7382dd24c'
var roleRbacAdministrator = 'f58310d9-a9f6-439a-9e8d-f62e7b41a168'


// Give developers contributor access to resource group in parameter developersResourceGroup
module roleAssignmentResourceGroup1 'roleAssignment.bicep' = {
  name: guid(developersResourceGroup, keyVaultDevelopersId, 'Contributor')
  scope: resourceGroup(developersResourceGroup)

  params: {
    roleAssignmentName: guid(resourceGroup().id, developersResourceGroup, keyVaultDevelopersId, 'Contributor')
    targetPrincipalId: keyVaultDevelopersId
    targetPrincipalType: 'Group'
    targetRoleId: roleContributor
  }
}

// Grant the developers rbac admin access t oresource group in parameter developersResourceGroup
module roleAssignmentResourceGroup2 'roleAssignment.bicep' = {
  name: guid(developersResourceGroup, keyVaultDevelopersId, 'RbacAdmin')
  scope: resourceGroup(developersResourceGroup)
  params: {
    roleAssignmentName: guid(resourceGroup().id, developersResourceGroup, keyVaultDevelopersId, 'RbacAdmin')
    targetPrincipalId: keyVaultDevelopersId
    targetPrincipalType: 'Group'
    targetRoleId: roleRbacAdministrator
  }
}


// Oprettele af den første private DNS zone til dev.api.private.aura.dk
resource privDns01 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: privDns01name
  location: 'global'
  tags: {
    costCenter: tagCostCenter
    opsTeam: tagOpsTeam
    Environment: tagEnvironment
  }
  properties: {  }
}


// Create the peering to the hub vnet in the hub subscription
// remote vnet id:  /subscriptions/35bb3b04-a290-4f1a-a6c4-b86e154947f1/resourceGroups/hub-subscription/providers/Microsoft.Network/virtualNetworks/hub-platform-vnet-001

var hubVnetId = '/subscriptions/35bb3b04-a290-4f1a-a6c4-b86e154947f1/resourceGroups/hub-subscription/providers/Microsoft.Network/virtualNetworks/hub-platform-vnet-001'

module peering001 'vnet-peering.bicep' = {
  name: 'peering001'
  params: {
    peeringName: 'toHubVnet'
    vnetName: virtualNetwork.name
    localPrefix: newVnewAddressPrefix
    remotePrefix: hubVnetAddressPrefix
    remoteVnetID: hubVnetId
  }
}


// DEPLOY CHANGES TO HUB-SUBSCRIPTION

var hubSubscriptionId = '35bb3b04-a290-4f1a-a6c4-b86e154947f1'
var hubResourceGroupName = 'hub-subscription'
var hubVnetName = 'hub-platform-vnet-001'

module peering002 'vnet-peering.bicep' = {
  name: 'peering002'
  scope: resourceGroup(hubSubscriptionId, hubResourceGroupName)
  params: {
    peeringName: 'fromHubVnet'
    vnetName: hubVnetName
    localPrefix: hubVnetAddressPrefix
    remotePrefix: newVnewAddressPrefix
    remoteVnetID: virtualNetwork.id
  }
}
