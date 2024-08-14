IKKE FÆRDIG ENDNU, VIRKER SANDSYNLIGVIS IKKE

<#
.SYNOPSIS
Identify-ServiceConnectionPrincipal.ps1 - Find information omkring Service Principal der anvendes til forbindelse fra Azure DevOps
til Azure.

.DESCRIPTION
Dette script finder information om den service principal der anvendes fra en Service Connection i Azure DevOps.

.OUTPUTS
bla bla bla

.PARAMETER DevOpsBaseUrl
URL til virksomhedesn Azure DevOps miljø.

Formatet er:

https://dev.azure.com/[virksomhed]

Værdien af [virksomhed] afhænger af hvordan virksomheden har registreret sig. Det kan både være virksomhedens navn, men også med
yderligere info på den.

.PARAMETER DevOpsProject
Angiv er navnet på det projekt i DevOps som skal checkes.

.PARAMETER Subscription
Angiv navnet på det subscription som der peges på fra Azure DevOps.

.PARAMETER ResrouceGroup
Angiv navnet på den resource group som indeholder den Cosmos Db instans der skal tildeles rettigheder til.

.PARAMETER CosmosDbName
Angiv navnet på den Cosmos Db ressourcer der skal tildeles rettigheder til.

.PARAMETER RoleName
Angiv navnet på den Cosmos Db rettighed der skal have adgangen tildelt.

Som standard anvendes "Cosmos Db Build-in Data Contributor".

.EXAMPLE
Get-ExternalUsers.ps1 -Count

[antal eksterne identificeret]

.EXAMPLE
Get-ExternalUsers.ps1 -Outfile exported-users.csv

[antal eksterne identificeret] personer er eksportere til filen exported-users.csv

.NOTES
Version:        1.0
Author:         Brian Lie Jørgensen (nhc)
For:            AURA
Creation date:  14-08-2024
Last update:    14-08-2024
#>


# Definer hvilket objekt du skal have fat i
# Den Service Principal som anvendes til service connection i Azure DevOps skal have tildelt rettigheder på DevOps databasen, så afhængigt af om service connection
# i DevOps er konfigureret med en Service Principal eller en Managed Identity - så er det dén der skal have adgang tildelt.


$devops_baseurl = "https://dev.azure.com/tfsaura"
$devops_project = "SMILE Integrations"
$subscription = "smile-fsintegration-sub-nonproduction-dinel"
$rg = "fsintegration-rg-d-dinel"
$cosmosdb = "smile-fs-int-cosmos-d-dinel"
$role_name = "Cosmos DB Built-in Data Contributor"
# $principal_type = "spn" or "mid"		# skal der gives adgang til enten Service Principal eller til Managed Identity
$principal_id = ""


# Login til de rette scopes
az login --scope https://management.core.windows.net//.default
az login --scope https://graph.microsoft.com//.default


# List roles der findes på Cosmos Db elementet
$role_id = az cosmosdb sql role definition list --account-name $cosmosdb --resource-group $rg | convertfrom-json | where-object {$_.roleName -eq $role_name} | select id


# Skal gerne returnere følgende roller:
# Cosmos DB Built-in Data Reader
# Cosmos DB Built-in Data Contributor
# det er den sidste der skal bruges, for at Service Principal får rettigheder til at skrive til dokumenter i databasen.

$project = az devops project show -p $devops_project | convertfrom-json

$connections = az devops service-endpoint list --organization $devops_baseurl --project $project.id | ConvertFrom-Json

foreach ($conn in $connections) {
  if ($conn.name -eq $subscription) {
    $principal_id = $conn.authorization.parameters.serviceprincipalid
    $ad_sp = az ad sp show --id $principal_id | convertfrom-json
    Write-Host "Service Connection:" $conn.name "is using Service Principal" $principal_id "   " $ad_sp.displayname
  }
}





