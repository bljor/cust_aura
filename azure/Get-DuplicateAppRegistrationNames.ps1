# Check for duplicate App Registration names in Entra ID

$all_apps = az ad app list --all | ConvertFrom-Json
$all_apps = $all_apps.displayname | select -Unique

Write-Host "Checking app registrations for duplicate names in use"
ForEach ($app in $all_apps) {
  $names = az ad app list --display-name $app | ConvertFrom-Json
  If ($names.count -gt 1) {
    Write-Host $app " - name was found" $names.count "times"
  }
}
