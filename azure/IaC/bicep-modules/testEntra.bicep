extension microsoftGraph

@description('Group to use')
param groupName string = ' AZ-DYNAMICS-DA-U-AURA CE Test2'

resource group 'Microsoft.Graph/groups@v1.0' existing = {
  uniqueName: groupName
}

output groupId string = group.id


/*
var groupName = 'AZ-LANDINGZONE-DA-U-CONTRIBUTOR-smile-fointegration-sub-nonproduction-dinel-development'

resource contributorGroup 'Microsoft.Graph/groups@v1.0' existing = {
  uniqueName: groupName
}

output groupId string = contributorGroup.id

*/
