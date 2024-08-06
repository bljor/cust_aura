# Virker ikke endnu ... afklar hvad der går galt

# Get all app ids used for endpoints in all projects in Azure DevOps

$projects = az devops project list --organization https://dev.azure.com/tfsaura | convertfrom-json | select-object -expand value

foreach ($proj in $projects) {
  $connections = az devops service-endpoint list --organization https://dev.azure.com/tfsaura --project $proj.id | convertfrom-json
  $spids = $spids + $connections.authorization.parameters.serviceprincipalid
}


# Get all app registrations from Entra ID
$all_apps = az ad app list --all | convertfrom-json | select appid,displayname

foreach ($app in $all_apps) {
  $appid = $app.id
  if ($spids -contains $appid) {
    write-host $app.displayname 'is used by DevOps'
  } else {
    write-host $app.displayname 'NOT USED BY DEVOPS'
  }
}



# Udtræk af alle projekter
$all_projects = az devops project list --organization https://dev.azure.com/tfsaura | convertfrom-json | select-object -expand value

Returnerer et object med følgende properties:

abbreviation:		(ukendt formål)
defaultTeamImageUrl:	(ukendt formål)
description:		Beskrivelse af projektet, indtastet af den der har oprettet det
id:			Unikt ID der identificerer projektet
lastUpdateTime:		Dato og tidspunkt for hvornår projektet sidst er opdateret
name:			Projekt navn, angivet af den der har oprettet projektet
revision:		(ukendt formål)
state:			(ukendt formål)
url:			URL der henviser til projektet
visibility:		(ukendt formål - antager at private betyder det ikke er offentligt tilgængeligt... Kan man oprette offentlige projekter?)



Når du har enten projekt navn eller projekt ID, kan du hente yderligere detaljer om projektet:

$project = az devops project show --project $projects[0].id | convertfrom-json | select-object -expand value