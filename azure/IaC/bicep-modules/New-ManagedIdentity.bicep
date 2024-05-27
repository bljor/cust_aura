resource symbolicname 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: 'extbjo-managed-identity'
  location: resourceGroup().location
  tags: {
    costCenter: 'IT-Drift'
    opsTeam: 'IT-Drift'
    Environment: 'Dev'
  }
}