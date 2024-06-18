$versions = @(
     "8.0.1910.12",
     "8.0.3810.9",
     "8.0.1710.11",
     "8.0.2020.8",
     "8.0.3510.10",
     "6.0.220",
     "8.0.1110.14",
     "8.0.1610.12",
     "8.0.4110.9",
     "8.0.2710.9"
)

$apps = Get-WmiObject -Class win32_product | where-object {$_.name -like '*java*'}
$remove = $false

foreach ($app in $apps) {
  if ($app.version -in $versions) {
     $remove = $true
  }
  if ($app.name -eq "Java Auto Updater") {
     $remove = $true
  }

  if ($remove) {
     write-host $app.Name "i versionen " $app.version " er på listen over software der skal fjernes og vil blive afinstalleret"
     $app.Uninstall()
  }
}
