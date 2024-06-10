param recoveryVaultName string
param location string = resourceGroup().location

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
