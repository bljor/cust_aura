

var storageAccountName = 'private dns zone name'
var tagCostCenter = ''
var tagOpsTeam = ''
var tagEnvironment = ''

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
