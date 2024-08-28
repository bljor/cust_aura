/*

Opret Container Registry

- husk
-- der skal tildeles rettigheder til service connection / service principal (den skal have contributor for at det virker)
   e.g. fra smile-hesintegration-sub-nonproduction dev miljø
   -- adgang tildelt til devops/SMILE Integrations/smile-hesintegration-dinel-development

-- åbning for at registry kan tilgås fra "public internet" ... Det skal låses ned, men det er der ikke tid til
-- 



Tildel den indbyggede 'Azure Cosmos DB Built-in Data Contributor' rolle til den principal der er oplyst. Principal skal være
Object ID på den Enterprise Application som er relateret til den service principal, der er konfigureret i Azure DevOps
Service Connection (der anvendes til deployment)

Der skulle være nogle muligheder:
https://stackoverflow.com/questions/76515887/how-to-programmatically-get-current-azure-devops-pipeline-object-id-in-order-to


Hvis Graph Extension skal bruges i Bicep - så husk, at property uniqueName skal udfyldes på grupper i forvejen.




NEDENSTÅENDE ER ARM KODE FOR DEN DER BLEV OPRETTET TIL HES

{
  sku: {
    name: 'Premium'
    tier: 'Premium'
  }
  type: 'Microsoft.ContainerRegistry/registries'
  id: '/subscriptions/a12d307e-13e0-425a-ac7a-e287154c6ab8/resourceGroups/smile-hesintegration-infrastructure-rg-d-dinel/providers/Microsoft.ContainerRegistry/registries/smilehesintegrationcrddinel'
  name: 'smilehesintegrationcrddinel'
  location: 'westeurope'
  tags: {
    CostCenter: 'CostCenter'
    Environment: 'Environment'
    OpsTeam: 'OpsTeam'
  }
  properties: {
    loginServer: 'smilehesintegrationcrddinel.azurecr.io'
    creationDate: '2024-08-20T07:59:38.6443976Z'
    provisioningState: 'Succeeded'
    adminUserEnabled: true
    networkRuleSet: {
      defaultAction: 'Allow'
      virtualNetworkRules: []
      ipRules: [
        {
          action: 'Allow'
          value: '13.79.56.76'
        }
      ]
    }
    policies: {
      quarantinePolicy: {
        status: 'disabled'
      }
      trustPolicy: {
        type: 'Notary'
        status: 'disabled'
      }
      retentionPolicy: {
        days: 7
        lastUpdatedTime: '2024-08-20T10:17:09.1501085+00:00'
        status: 'disabled'
      }
    }
  }
}

*/

var roleDefinitionContributor = 'b24988ac-6180-42a0-ab88-20f7382dd24c'    // use roleContributor instead
var contributorsGroupId = '2a6c4a99-aee8-455c-aa7a-ff18c3d4c842'
var servicePrincipalId = '6cd076c3-e29d-438b-99f8-75934bc70db3'       // The Service Principal used by the service connection 

resource containerRegistry 'Microsoft.ContainerRegistry/registries@2023-11-01-preview' = {

  name: 'smilehesintegrationcrtdinel'
  location: resourceGroup().location

  sku:{
    name: 'Premium'
  }

  tags: {
    CostCenter: 'Dinel'
    Environment: 't'
    OpsTeam: 'IT-Drift'
  }
  
  properties: {
    adminUserEnabled: true
    networkRuleSet: {
      defaultAction: 'Allow'
      ipRules: [
          {
            action: 'Allow'
            value: '13.79.56.76'
          }
      ]
    }
    policies: {
      quarantinePolicy: {
        status: 'disabled'
      }
      trustPolicy: {
        type: 'Notary'
        status: 'disabled'
      }
      retentionPolicy: {
        days: 7
      }
    }
  }
}



//grant access to Developers as well
// group name: AZ-LANDINGZONE-DA-U-CONTRIBUTOR-smile-fsintegration-sub-nonproduction-dinel-dev
// group id: 2a6c4a99-aee8-455c-aa7a-ff18c3d4c842

// 




resource roleAssignmentContainerRegistry 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid('Grant access to Container Registry for DevOps Service Connection')
  properties: {
    roleDefinitionId: resourceId('MIcrosoft.Authorization/roleDefinitions', roleDefinitionContributor)
    principalId: servicePrincipalId
    principalType: 'ServicePrincipal'
  }
  
}

/*
resource roleAssignment004 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid('Role Assignment - let developers access ${managedGrafana.name} - (Role: Grafana Admin)')
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', roleGrafanaAdminId)
    principalId: contributorGroupId
    principalType: 'Group'
  }
}
*/
