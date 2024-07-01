/*

  Anvendes til at tildele RBAC roller

*/

@description('Navn på role assingment')
param roleAssignmentName string
@description('ID på den RBAC rolle der skal tildeles identiteten')
param targetRoleId string
@description('ID på den identititet som skal have tildelt adgangen')
param targetPrincipalId string
@description('Hvilken identitets type der skal gives adgang til')
@allowed([
  'Device'
  'ForeignGroup'
  'Group'
  'ServicePrincipal'
  'User'
])
param targetPrincipalType string

resource roleAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: roleAssignmentName
  properties: {
    roleDefinitionId: resourceId('Microsoft.Authorization/roleDefinitions', targetRoleId)
    principalId: targetPrincipalId
    principalType: targetPrincipalType
  }
}
