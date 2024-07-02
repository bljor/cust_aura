param storageAccountName string
param location string = resourceGroup().location

resource storageAccount 'Microsoft.Storage/storageAccounts@2022-05-01' = {
  name: storageAccountName
  location: location

  tags: {
    Environment: 'Dev'
    OpsTeam: 'IT-Drift'
    CostCenter: 'Dinel'
  }

  sku: {
    name: 'Standard_LRS'                      // 
  }

  kind: 'Storage'

  properties: {
    allowBlobPublicAccess: false              // 
    allowCrossTenantReplication: false        // 
    allowedCopyScope: 'AAD'                   // 
    allowSharedKeyAccess: false               // 
    minimumTlsVersion: 'TLS1_2'               // 
    publicNetworkAccess: 'Disabled'           // 
    
  }
}
