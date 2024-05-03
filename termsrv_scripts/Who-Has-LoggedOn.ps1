<#
.SYNOPSIS
Who-Has-LoggedOn.ps1 - Viser oplysninger om brugere der har været logget på serveren. Finder brugere ud fra events i Event Loggen.

Finder alle events i System loggen med Event ID 7001    (som svarer til at bruger er logget på).

Event indeholder kun SID på brugeren, så alle brugere fra AD'et hentes ud i et array (med navn, sid og userprincipalname). Ud fra dette SID findes den bruger der har logget på.

Der printes en liste over tidspunkter for logon sammen med brugerens navn og SID.

.DESCRIPTION
Finder alle events i System loggen med Event ID 7001    (som svarer til at bruger er logget på).

Event indeholder kun SID på brugeren, så alle brugere fra AD'et hentes ud i et array (med navn, sid og userprincipalname). Ud fra dette
SID findes den bruger der har logget på.

.OUTPUTS
Returnerer en liste over tidspunkter og brugere hvor vedkommende har logget på serveren.

.PARAMETER (ingen))
Scriptet tager ingen parametre.

.EXAMPLE
Who-Has-LoggedOn.ps1

.NOTES
Version:	1.0
Author:		NHC / Brian Lie Jørgensen (bjo@nhc.dk)
For:		Aura a.m.b.a.
Creation date:	25/01/2024
Last update:	25/01/2024


Change Log:
v1.0	25/01/2024	- Brian Lie Jørgensen, NHC
#>

Write-Host "Reading users from Active Directory"
$Users = Get-AdUser -Filter * | Select Name,sid,userprincipalname
Write-Host "Retrieving log entries from the System log"
$logs = Get-EventLog -LogName System -Source Microsoft-Windows-Winlogon | Where-Object {$_.EventId -eq 7001}

ForEach ($log in $logs) {
    $usr = $users | Where-Object {$_.sid -eq $log.replacementstrings[1]}
    Write-Host $log.timegenerated $usr.name $usr.userprincipalname $usr.sid
}