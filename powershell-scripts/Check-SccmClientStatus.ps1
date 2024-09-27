<#
.SYNOPSIS
Check-SccmClientStatus-ps1 - Check SCCM klienter på servere.
Script der checker alle servere fundet i AD'et for om der er installeret en SCCM klient, at den er kørende - og at den er forbundet
til det rigtige site (det samme site, som dét site serveren scriptet afvikles fra er tilknyttet).

.DESCRIPTION
Dette script finder alle servere i Active Directory, forbinder til hver enkelt og checker om der er instealleret en SCCM agent på serveren.

Resultatet skrives til en CSV-fil.

.OUTPUTS
Der vises en linje på skærmen for hver server der undersøges. Når alle servere er "analyseret" skrives resultatet for alle servere til en .CSV-fil.

.PARAMETER ClientType
Angiver hvilken type klienter der skal undersøges.

Mulige værdier er:

  Servers          Finder servere i AD'et og rapporterer på dem
  Clients          Finder Windows klienter i AD'et og rapporterer på dem
  All		   Finder både servere og Windows klienter i AD'et og rapporterer på dem

.PARAMETER OutFile
Angiver hvilken fil resultatet skal skrives til. Hvis der ikke angives en fuld sti, så skrives der til samme folder som scriptet afvikles fra.

Hvis parameter ikke angives, så skrives til Check-SccmClientStatus.csv

.PARAMETER Delimiter
Angiver hvilken seperator der anvendes til at adskille de forskellige værdier i eksporten.

Hvis parameter ikke specificeres, så anvendes som standard semikolon (;)

.PARAMETER Overwrite
Angiver hvorvidt eksisterende output-fil skal overskrives.
Hvis parameter ikke angives, og filen findes findes i forvejen - så vil der blive tilføjet data til den eksisterende. Inkluderende eventuelle kolonneoverskriver og andet indledende tekst.

Transcript log-filen bliver ALTID slettet, inden en ny oprettes.

.EXAMPLE
.\Check-SccmClientStatus.ps1 -outfile c:\temp\Sccm-Export.csv

Her eksporters information til filen c:\temp\Sccm-Export.csv og anvender standard-adskiller som kolonne-adskiller i eksporten.

.NOTES
Version:	1.0
Author:		Brian Lie Jørgensen (brian@wipe.dk)
For:		  AURA
Creation date:	18/09/2024
Last update:	  26/09/2024

Change Log:
v1.0	18/09/2024		- NHC, Brian Lie Jørgensen
v1.1  26/09/2024    - NHC, Brian Lie Jørgensen

#>

param (
	[Parameter(Mandatory=$false)]
        [ValidateSet('servers','clients','all')]
        [string]$ClientType = "Servers",
        [Parameter(Mandatory=$false)]
	[string]$OutFile = "Check-SccmClientStatus.csv",
	[Parameter(Mandatory=$false)]
	[char]$Delimiter = ";",
        [Parameter(Mandatory=$false)]
        [switch]$Overwrite=$false
)

$output = @()

Start-Transcript Check-SccmClientStatus.log

$local_status = (Get-WmiObject Win32_Service -ErrorAction SilentlyContinue | Where-Object {$_.name -eq "ccmexec"}).State
If ($local_status -eq 'Running') {
  $local_client = Get-WmiObject -List -NameSpace root\ccm -Class SMS_Client -ErrorAction SilentlyContinue
  $local_site = $local_client.getassignedsite().ssitecode

  # Determine the scope of investigations from the ClientType parameter

  If ($ClientType -eq 'servers') {
    $servers = Get-AdComputer -Filter {operatingsystem -like '*server*' -and enabled -eq $true} -properties operatingsystem,lastlogontimestamp
  } elseif ($ClientType -eq 'clients') {
    $servers = Get-AdComputer -Filter {operatingsystem -notlike '*server*' -and enabled -eq $true} -properties operatingsystem,lastlogontimestamp
  } else {
    $servers = Get-AdComputer -Filter {enabled -eq $true} -Properties operatingsystem,lastlogontimestamp
  }

  Write-Host "Performing check on" $servers.count devices "... this might take a while."
	
  ForEach ($server in $servers) {

    Write-Host "Checking device $server.name"

    If (Test-Connection -ComputerName $server.name -Count 1 -ErrorAction SilentlyContinue) {

      $sccm_client_status = ((Get-WmiObject Win32_Service -ComputerName $server.name -ErrorAction SilentlyContinue | Where-Object {$_.name -eq "ccmexec"}).State)

      If ($sccm_client_status -eq 'Running') {

        $sccm_client_version = (Get-WmiObject -NameSpace "root\ccm" -ComputerName $server.name -Class sms_client).ClientVersion

        $sccm_client = Get-WmiObject -ComputerName $server.name -list -NameSpace root\ccm -Class SMS_Client -ErrorAction SilentlyContinue

        $site = $sccm_client.getassignedsite().ssitecode

        $srv = [pscustomobject]@{DeviceName=$server.name;ServerStatus="Responding";LastSeen=[datetime]::FromFileTime($server.lastlogontimestamp);SccmStatus=$sccm_client_status;SccmVersion=$sccm_client_version;SccmSite=$site}

      } else {
	$srv = [pscustomobject]@{DeviceName=$server.name;ServerStatus="Responding";LastSeen=[datetime]::FromFileTime($server.lastlogontimestamp);SccmStatus="Not installed"}
      }
    } else {
      $srv = [pscustomobject]@{DeviceName=$server.name;ServerStatus="Not responding";LastSeen=[datetime]::FromFileTime($server.lastlogontimestamp)}
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
$output | Export-Csv -Path $OutFile -Delimiter $Delimiter -Encoding UTF8 -Force -NoTypeInformation
5
Stop-Transcript
