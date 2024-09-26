<#

.SYNOPSIS
Script der checker alle servere fundet i AD'et for om der er installeret en SCCM klient, at den er kørende - og at den er forbundet
til det rigtige site (det samme site, som dét site serveren scriptet afvikles fra er tilknyttet).

#>

$output = @()

Start-Transcript Check-SccmClientStatus.log

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

      } else {
	$srv = [pscustomobject]@{ServerName=$server.name;ServerStatus="Responding";SccmStatus="Not installed"}
      }
    } else {
      $srv = [pscustomobject]@{ServerName=$server.name;ServerStatus="Not responding"}
    }
    $output += $srv

    $srv = ""
    $sccm_client_status = ""
    $sccm_client_version = ""
    $sccm_client = ""
    $site = ""
  }
} else {
  Write-Host "No SCCM client found on local computer"
}

If (Get-Item "Check-SccmClientStatus.csv" -ErrorAction SilentlyContinue) { Remove-Item "Check-SccmClientStatus.csv" }
$output | Export-Csv -Path Check-SccmClientStatus.csv -Delimiter ";" -Encoding UTF8 -Force -NoTypeInformation

Stop-Transcript
