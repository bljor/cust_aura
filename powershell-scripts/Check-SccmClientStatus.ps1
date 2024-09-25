<#

.SYNOPSIS
Script der finder alle servere i AD'et, og efterfølgende forbinder til dem en for én, og checker hvorvidt der er installeret en SCCM
klient på serveren.

Hvis der er en klient, checkes status på klienten ligesom versionsnummeret på klienten bliver logget.

Yderligere, logges hvilket SCCM site klienten er konfigureret til at bruge.

#>

$output = @()

Start-Transcript check-sccm-client-status.log

$local_status = (Get-WmiObject Win32_Service -ErrorAction SilentlyContinue | Where-Object {$_.name -eq "ccmexec"}).State
If ($local_status -eq 'Running') {
  $local_client = Get-WmiObject -List -NameSpace root\ccm -Class SMS_Client -ErrorAction SilentlyContinue
  $local_site = $local_client.getassignedsite().ssitecode

  $servers = Get-AdComputer -Filter {operatingsystem -like '*server*'} -properties operatingsystem

  ForEach ($server in $servers) {

    Write-Host "Checking server $server.name"

    If (Test-Connection -ComputerName $server.name -Count 1 -ErrorAction SilentlyContinue) {

      $sccm_client_status = ((Get-WmiObject Win32_Service -ComputerName $server.name -ErrorAction SilentlyContinue | Where-Object {$_.name -eq "ccmexec"}).State)

      If ($sccm_client_status -eq 'Running') {

        $sccm_client_version = (Get-WmiObject -NameSpace "root\ccm" -ComputerName $server.name -Class sms_client).ClientVersion

        $sccm_client = Get-WmiObject -ComputerName $server.name -list -NameSpace root\ccm -Class SMS_Client -ErrorAction SilentlyContinue

        $site = $sccm_client.getassignedsite().ssitecode

        $srv = [pscustomobject]@{ServerName=$server.name;ServerStatus="Responding";SccmStatus=$sccm_client_status;SccmVersion=$sccm_client_version;SccmSite=$site}

        $output += $srv
        $srv = ""
      } else {
	$srv = [pscustomobject]@{ServerName=$server.name;ServerStatus="Responding";SccmStatus="Not installed"}
      }
    } else {
      $srv = [pscustomobject]@{ServerName=$server.name;ServerStatus="Not responding"}
      $output += $srv
      $srv = ""
    }
  }
} else {
  Write-Host "No SCCM client found on local computer"
}

If (Get-Item "Check-SccmClientStatus.csv" -ErrorAction SilentlyContinue) { Remove-Item "Check-SccmClientStatus.csv" }
$output | Export-Csv -Path Check-SccmClientStatus.csv -Delimiter ";" -Encoding UTF8 -Force

Stop-Transcript
