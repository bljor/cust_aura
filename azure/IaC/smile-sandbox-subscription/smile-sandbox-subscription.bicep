// Configures the Sandbox subscription in Azure with resource groups

// smile-fsintegration-rg-d-dinel
// smile-fsintegration-infrastructure-rg-d-dinel

targetScope = 'subscription'

resource infrastructureResourceGroup 'Microsoft.Resources/resourceGroups@2024-03-01' = {

  name: 'smile-fsintegration-infrastructure-rg-d-dinel'
  location: 'westeurope'
  tags: {
    Environment: 'sandbox'
    CostCenter: 'Dinel'
    OpsTeam: 'IT-Drift'
    Organization: 'Dinel'
  }
}

resource codeResourceGroup 'Microsoft.Resources/resourceGroups@2024-03-01' = {

  name: 'smile-fsintegration-rg-d-dinel'
  location: 'westeurope'
  tags: {
    Environment: 'sandbox'
    CostCenter: 'Dinel'
    OpsTeam: 'IT-Drift'
    Organization: 'Dinel'
  }
}


