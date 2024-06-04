// source for this document, which hasn't been finished yet
// https://learn.microsoft.com/en-us/azure/templates/microsoft.network/routetables?pivots=deployment-language-bicep

resource myRouteTable 'Microsoft.Network/routeTables@2023-11-01' = {
  name: 'name-of-route-table'
  location: resourceGroup().location
  tags: {
    OpsTeam: 'IT-Drift'
    CostCenter: 'Dinel'
    Environment: 'Dev'
  }

properties: {
  disableBgpRoutePropagation: false

  routes: [
    {
      
    }
  ]
}

}
