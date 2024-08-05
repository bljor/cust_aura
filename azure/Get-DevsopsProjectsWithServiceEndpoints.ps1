# Virker ikke endnu ... afklar hvad der går galt

# Get all app ids used for endpoints in all projects in Azure DevOps

$projects = az devops project list --organization https://dev.azure.com/tfsaura | convertfrom-json | select-object -expand value

foreach ($proj in $projects) {
  $connections = az devops service-endpoint list --organization https://dev.azure.com/tfsaura --project $proj.id | convertfrom-json
  $spids = $spids + $connections.authorization.parameters.serviceprincipalid
}


# Get all app registrations from Entra ID
$all_apps = az ad app list --all | convertfrom-json | select id,displayname

foreach ($app in $all_apps) {
  $appid = $app.id
  foreach ($spid in $spids) {
    if ($spid.id -eq $appid) {
      write-host $app.displayname 'is used in DevOps'
    }
  }
}
