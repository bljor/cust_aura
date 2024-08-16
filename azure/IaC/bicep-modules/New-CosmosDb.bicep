@description('Specifies the name of the Cosmos DB account.')
param databaseAccounts_cosmos_name string
 
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
