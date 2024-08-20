
/*

Den gruppe der ledes efter, hvis man laver en existing reference i Bicep
skal have uniqueName property udfyldt. Det har grupper i Entra ID ikke
pr. automatik - så noget skal gøres

Opdater uniqueName property på en bestemt gruppe med disse kommandoer:

az rest --method patch --url 'https://graph.microsoft.com/v1.0/groups/<replace-with-ID-of-your-group>' --body '{\"uniqueName\": \"TestGroup-2024-05-10\"}' --headers "content-type=application/json"
az rest --method patch --url 'https://graph.microsoft.com/v1.0/applications/<replace-with-ID-of-your-application>' --body '{\"uniqueName\": \"TestApp-2024-05-10\"}' --headers "content-type=application/json"

I praksis for gruppen AZ-LANDINGZONE-DA-U-CONTRIBUTOR-smile-fointegration-sub-nonproduction-dinel-development (som har objekt ID: 2779dfd6-9935-49a3-9b77-d15b4c6d5c06)

az rest --method patch --url 'https://graph.microsoft.com/v1.0/groups/2779dfd6-9935-49a3-9b77-d15b4c6d5c06' --body '{\"uniqueName\": \"AZ-LANDINGZONE-DA-U-CONTRIBUTOR-smile-fointegration-sub-nonproduction-dinel-development\"}' --headers "content-type=application/json"

Som sætter uniqueName til en kendt værdi.

*/


extension microsoftGraph

@description('Group to use')
param groupName string = 'AZ-DYNAMICS-DA-U-AURA CE Test2'

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
