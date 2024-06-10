param keyVaultName string
param location string = resourceGroup().location

// Key Vault til opbevaring af certifikater og nøgler
resource keyvaultcerts 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: keyVaultName                          // Streng >= 3 og <= 24 tegn
  location: location

  tags: {
    Environment: 'Dev'
    OpsTeam: 'IT-Drift'
    CostCenter: 'Dinel'
  }

  properties: {
    enabledForDeployment: false               // Må Azure VMs hente certifikater gemt som secrets, fra denne Key Vault?
    enabledForDiskEncryption: false           // Må Azure Disk Encryption hente  secrets fra denne Key Vault?
    enabledForTemplateDeployment: false       // Må Azure Resource Manager hente secrets fra denne Key Vault?
    tenantId: subscription().tenantId
    enableSoftDelete: true                    // Vil blive sat til true, medmindre denne værdi er false.
    softDeleteRetentionInDays: 90             // Antal dage secrets kan gendannes - skal være >= 7 og <= 90 dage.
    enablePurgeProtection: true               // Har kun effekt, hvis Soft Delete også er aktiveret. Kan ikke ændres, når først den er sat.
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
      defaultAction: 'Allow'                  // Hvilken action tages, hvis hverken ipRules eller virtualNetworkRules matches? (Allow / Deny)
      bypass: 'AzureServices'                 // Hvilke services kan omgå networkAcls? Kan være 'AzureServices' eller 'None'
    }
    publicNetworkAccess: 'disabled'           // 'disabled' = tillader kun adgang fra private endpoints og trusted services.
  }
}
