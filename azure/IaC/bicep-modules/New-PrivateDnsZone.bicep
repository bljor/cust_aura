

var storageAccountName = 'wipe.dev.brian'
var tagCostCenter = 'Dinel'
var tagOpsTeam = 'IT-Drift'
var tagEnvironment = 'Dev'

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: storageAccountName
  location: 'global'
  tags: {
    costCenter: tagCostCenter
    opsTeam: tagOpsTeam
    Environment: tagEnvironment
  }
  properties: {  }
}
