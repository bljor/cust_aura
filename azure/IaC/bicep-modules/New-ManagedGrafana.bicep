/*

Deployer en Managed Grafana instans i Azure
Der oprettes automatisk en Managed Identity (i Entra ID, under Enterprise Applications)

Tilføj rollen 'Grafana Admin' til Contributor gruppen for den landing zone der deployes til
- e.g.

- AZ-LANDINGZONE-DA-U-CONTRIBUTOR-smile-hesintegration-sub-sandbox-dinel-dev
- AZ-LANDINGZONE-DA-U-CONTRIBUTOR-smile-hesintegration-sub-nonproduction-dinel-dev

*/

//extension microsoftGraph        Kan ikke få det til at virke, med at finde ID på en eksisterende gruppe i Entra ID

var managedGrafanaName = 'bjosamp-fo-graf-d-dinel'

var tagCostCenter = 'Dinel'
var tagOpsTeam = 'IT-Drift'
var tagEnvironment = 'Dev'

var roleGrafanaAdminId = '22926164-76b3-42b3-bc55-97df8dab3e41'       // ID of the Grafana Admin role definition
var contributorGroupId = '4c978141-15d0-4a12-87ac-9cb2461eae69'       // ID of the AZ-LANDINGZONE-DA-U-CONTRIBUTOR-smile-fointegration-sub-nonproduction-dinel-development group


resource managedGrafana 'Microsoft.Dashboard/grafana@2023-09-01' = { 

  name: managedGrafanaName
  sku: {
    name: 'Standard'
  }

  location: resourceGroup().location
  tags: {
    costCenter: tagCostCenter
    opsTeam: tagOpsTeam
    Environment: tagEnvironment
  }

  identity: {
    type: 'SystemAssigned'
  }

  properties: {
    apiKey: 'Disabled'
    autoGeneratedDomainNameLabelScope: 'TenantReuse'
    deterministicOutboundIP: 'Disabled'
    grafanaMajorVersion: '10'
    zoneRedundancy: 'Disabled'
    publicNetworkAccess: 'Enabled'
    grafanaIntegrations: {
      azureMonitorWorkspaceIntegrations: []
    }
    grafanaConfigurations: {
      smtp: {
        enabled: false
      }
    }
  }
}


// Grant "Grafana Admin" role to users
resource roleAssignment01 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid('Role Assignment - let developers access ${managedGrafana.name} - (Role: Grafana Admin)')
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', roleGrafanaAdminId)
    principalId: contributorGroupId
    principalType: 'Group'
  }
}
