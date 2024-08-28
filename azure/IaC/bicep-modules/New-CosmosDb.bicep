/*

Opret Cosmos Db ressource
Tildel den indbyggede 'Azure Cosmos DB Built-in Data Contributor' rolle til den principal der er oplyst. Principal skal være
Object ID på den Enterprise Application som er relateret til den service principal, der er konfigureret i Azure DevOps
Service Connection (der anvendes til deployment)

Der skulle være nogle muligheder:
https://stackoverflow.com/questions/76515887/how-to-programmatically-get-current-azure-devops-pipeline-object-id-in-order-to


Hvis Graph Extension skal bruges i Bicep - så husk, at property uniqueName skal udfyldes på grupper i forvejen.



*/

@description('Specifies the name of the Cosmos DB account.')
//param databaseAccounts_cosmos_name string
var databaseAccounts_cosmos_name = 'extbjo01-cosmos-d-dinel'
var serviceConnectionSpid = 'a5125e3f-94dd-478d-907f-1c35d0b8bb12'    // The Object ID of the Enterprise Application matching the Service Principal used by Azure DevOps Service Connection
var roleCosmosDataContributor = '/subscriptions/692a57dc-fed3-4ff6-a5d7-7ed5a11a2240/resourceGroups/bjo-sample-rg-d-dinel/providers/Microsoft.DocumentDB/databaseAccounts/extbjo-cosmos-d-dinel/sqlRoleDefinitions/00000000-0000-0000-0000-000000000002'

///subscriptions/3336ebfa-a1f5-4920-a951-78ad5d6b73ec/resourceGroups/bjo-sample-rg-d-dinel/providers/Microsoft.DocumentDB/databaseAccounts/extbjo-cosmos-t-dinel/
///subscriptions/3336ebfa-a1f5-4920-a951-78ad5d6b73ec/resourceGroups/bjo-sample-rg-d-dinel/providers/Microsoft.DocumentDB/databaseAccounts/extbjo-cosmos-t-dinel/sqlRoleDefinitions/00000000-0000-0000-0000-000000000002
//var roleCosmosDataContributor = '/subscriptions/${subscription().subscriptionId}/resourceGroups/${resourceGroup().name}/providers/Microsoft.DocumentDB/databaseAccounts/${databaseAccounts_cosmos_name}/sqlRoleDefinitions/00000000-0000-0000-0000-000000000002}'

 
@description('Specifies the location for all resources.')
param location string = resourceGroup().location // Location of the resources

// Parameters for resource tagging
@description('Cost center tag')
param TagCostCenter string = 'DinEl'
@description('Environment tag (e.g., Dev, Test, Prod)')
param TagEnvironment string = 'Dev'
@description('Operations team tag')
param TagOpsTeam string = 'IT-Udvikling'
 
@description('The Azure Cosmos DB offer type')
@allowed([
  'Standard'
])
param documentDBOfferType string = 'Standard'
 
@description('The Azure Cosmos DB default consistency level for this account.')
@allowed([
  'Eventual'
  'Strong'
  'Session'
  'BoundedStaleness'
])
param consistencyLevel string = 'Session'
 
@description('When consistencyLevel is set to BoundedStaleness, then this value is required, otherwise it can be ignored.')
@minValue(10)
@maxValue(1000)
param maxStalenessPrefix int = 10
 
@description('When consistencyLevel is set to BoundedStaleness, then this value is required, otherwise it can be ignored.')
@minValue(5)
@maxValue(600)
param maxIntervalInSeconds int = 5
 
// Resource definition for Cosmos DB account
resource databaseAccounts_resource 'Microsoft.DocumentDB/databaseAccounts@2023-11-15' = {
  name: databaseAccounts_cosmos_name
  location: location
  tags: {
    defaultExperience: 'Core (SQL)'
    CostCenter: TagCostCenter
    Environment: TagEnvironment
    OpsTeam: TagOpsTeam
  }
  properties: {
    databaseAccountOfferType: documentDBOfferType
    consistencyPolicy: {
      defaultConsistencyLevel: consistencyLevel
      maxStalenessPrefix: maxStalenessPrefix
      maxIntervalInSeconds: maxIntervalInSeconds
    }
    locations: [
      {
        locationName: location
        failoverPriority: 0
      }
    ]
  }
  kind: 'GlobalDocumentDB'
  identity: {
    type: 'None'
  }
}
 
 
// Resource for creating a SQL database within the Cosmos DB account
resource databaseAccounts_db_LogHandler 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases@2023-11-15' = {
  parent: databaseAccounts_resource
  name: 'LogHandler'
  properties: {
    resource: {
      id: 'LogHandler'
    }
  }
}
 
// Resource for creating a container named 'BuildInfo' in the 'LogHandler' SQL database
resource databaseAccounts_smile_cosmos_d_dinel_name_BuildInfo_Events 'Microsoft.DocumentDB/databaseAccounts/sqlDatabases/containers@2023-11-15' = {
  parent: databaseAccounts_db_LogHandler
  name: 'BuildInfo'
  properties: {
    resource: {
      id: 'BuildInfo'
       partitionKey: {
        paths: [
          '/partitionKey'
        ]
        kind: 'Hash'
      }
    }
  }
}

/*

// Retrieve the role definition ID of the "Cosmos DB Build-in Data Contributor" role
// can it be done?
resource roleDefinition 'Microsoft.DocumentDB/databaseAccounts/sqlRoleDefinitions@2024-05-15' existing = {
  name: 'Cosmos DB Built-in Data Contributor'
  properties: {}

}
*/

// Grant "Cosmos DB Built-in Data Contributor" role to the enterprise app referenced in the service connection in Azure DevOps
resource roleAssignment01 'Microsoft.DocumentDB/databaseAccounts/sqlRoleAssignments@2024-05-15' = {
  name: guid('cosmosDbRoleAssignment')
  parent: databaseAccounts_resource

  properties: {
    principalId: serviceConnectionSpid
    roleDefinitionId: roleCosmosDataContributor
    scope: databaseAccounts_resource.id
  }
}
