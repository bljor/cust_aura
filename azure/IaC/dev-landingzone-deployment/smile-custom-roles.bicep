targetScope = 'subscription'

@description('Array of actions for the roleDefinition')
param actions array = [
  'Microsoft.Network/virtualNetworks/subnets/join/action'
]

@description('Array of notActions for the roleDefinition')
param notActions array = []

@description('Friendly name of the role definition')
param roleName string = '[AURA] Network-VirtualNetworks-Subnets-Join'

@description('Detailed description ofthe role definition')
param roleDescription string = 'Grants access to join subnets in a virtual network'

var roleDefName = guid(roleName)

resource roleDef 'Microsoft.Authorization/roleDefinitions@2022-05-01-preview' = {
  name: roleDefName
  properties: {
    roleName: roleName
    description: roleDescription
    type: 'customRole'
    permissions: [
      {
        actions: actions
        notActions: notActions
      }
    ]
    assignableScopes: [
      subscription().id
    ]
  }
}
