resource rbacAdminRole 'Microsoft.Authorization/roleDefinitions@2022-05-01-preview' existing = {
  name: 'Key Vault Certificates Officer'
}


output newtest string = rbacAdminRole.properties.roleName


/*

output rolename string = rbacAdminRole.name
output roleid string = rbacAdminRole.id
output test string = rbacAdminRole.properties.roleName

*/


