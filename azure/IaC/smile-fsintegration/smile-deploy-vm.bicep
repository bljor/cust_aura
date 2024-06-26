@description('Password for the Virtual Machine.')
@minLength(12)
@secure()
param adminPassword string


// Variabler til oprettelse af Network Interface Card (nic)
var nicName = 'fs-integra1-nic01'

// Delte variable på tværs af ressourcer
var location = resourceGroup().location
var tagCostCenter = 'Dinel'
var tagOpsTeam = 'IT-Drift'
var tagEnvironment = 'Dev'

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


// Variabler til oprettelse af VNET
var virtualNetworkName = 'smile-fsintegration-vnet-001-d-dinel'


// Variabler til oprettelse af Storage Account
var storageAccountName = 'stfsintegdaura'


// Reference the existing storage account
resource storageAccount 'Microsoft.Storage/storageAccounts@2022-05-01' existing = {
  name: storageAccountName
}


// Virtual network - refererer til både Network Security Group defineret ovenfor,
// samt route table nedenfor
resource virtualNetwork 'Microsoft.Network/virtualNetworks@2022-05-01' existing = {
  name: virtualNetworkName
}


// Network Interface - relateret til ovenstående Virtual Network
resource nic 'Microsoft.Network/networkInterfaces@2022-05-01' = {
  name: nicName
  location: resourceGroup().location
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
}



// Oprettelse af den virtuelle maskine, afhænger af ovenstående Network Interface
resource vm 'Microsoft.Compute/virtualMachines@2022-03-01' = {
  name: vmName
  location: resourceGroup().location
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
  tags: {
    opsTeam: tagOpsTeam
    costCenter: tagCostCenter
    Environment: tagEnvironment
    ExceptionToPolicyRequireBackup: 'True'
  }
  properties: {
    publisher: extensionPublisher
    type: extensionType
    typeHandlerVersion: extensionVersion
    autoUpgradeMinorVersion: true
  }
}


