
// oprettelse af Key Vault til lagring af admin credentials
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
