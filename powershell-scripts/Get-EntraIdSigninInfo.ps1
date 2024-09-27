<#
.SYNOPSIS
Get-EntraSigninInfo.ps1 - eksporterr information om brugere og login fra Entra ID.

REQUIREMENTS:

- Du skal være Global Administrator for at kunne afvikle scriptet (og du skal i forbindelse med afviklingen godkende at scriptet kører med de rettigheder det gør).
- Du skal bruge modulet Microsoft.Graph.Beta.Users, hvis det ikke findes på maskinen - så skal det installeres.
  install-module Microsoft.Graph.Beta.Users -AllowClobber -Force

.DESCRIPTION
Dette script laver et udtræk af alle brugere fra Entra ID (incl. guest accounts), og rapporterer på hvornår hver enkelt bruger sidst har været logget på.

Resultatet skrives til en CSV-fil.

.OUTPUTS
Scriptet rapporterer ikke andet end status til skærmen, når alle data er fundet skrives de til en .CSV fil.

.PARAMETER UserType
Angiver hvilken type klienter der skal undersøges.

Mulige værdier er:

  Members      Rapporterer om organizationens egne brugere
  Guests       Rapporterer om eksterne brugere som er inviteret ind i Entra ID som Guest accounts
  All		   Rapporterer på alle typer af brugere.

.PARAMETER OutFile
Angiver hvilken fil resultatet skal skrives til. Hvis der ikke angives en fuld sti, så skrives der til samme folder som scriptet afvikles fra.

Hvis parameter ikke angives, så skrives til Get-EntraSigninInfo.csv

.PARAMETER Delimiter
Angiver hvilken seperator der anvendes til at adskille de forskellige værdier i eksporten.

Hvis parameter ikke specificeres, så anvendes som standard semikolon (;)

.PARAMETER Overwrite
Angiver hvorvidt eksisterende output-fil skal overskrives.
Hvis parameter ikke angives, og filen findes findes i forvejen - så vil der blive tilføjet data til den eksisterende. Inkluderende eventuelle kolonneoverskriver og andet indledende tekst.

Transcript log-filen bliver ALTID slettet, inden en ny oprettes.

.EXAMPLE
.\Get-EntraSigninInfo.ps1 -ClientType Member -outfile c:\temp\EntraSignIn-info.csv

Her eksporters information til filen c:\temp\EntraSignIn-info.csv og anvender standard-adskiller som kolonne-adskiller i eksporten.

.NOTES
Version:	1.0
Author:		Brian Lie Jørgensen (brian@wipe.dk)
For:		AURA
Creation date:	27/09/2024
Last update:	  27/09/2024

Change Log:
v1.0	27/09/2024		- NHC, Brian Lie Jørgensen

#>

param (
	[Parameter(Mandatory=$false)]
    [ValidateSet('members','guests','all')]
    [string]$ClientType = "Members",
    [Parameter(Mandatory=$false)]
	[string]$OutFile = "Get-EntraSigninInfo.csv",
	[Parameter(Mandatory=$false)]
	[char]$Delimiter = ";",
    [Parameter(Mandatory=$false)]
    [switch]$Overwrite=$false
)

$output = @()

Start-Transcript Get-EntraSigninInfo.log

If ((Get-Module Microsoft.Graph.Beta.Users).Count -eq 0) {
    Write-Host "You should install the module Microsoft.Graph.Beta.Users to run this script"
    Stop-Transcript
    Exit
}

Import-Module Microsoft.Graph.Beta.Users
Connect-MgGraph -Scope AuditLog.Read.All

$szAttributes = "usertype,userprincipalname,displayname,signinactivity,LastPasswordChangeDateTime,createddatetime,companyname,OnPremisesLastSyncDateTime"

# Quick and dirty filter build-up ... could be written more elegantly
If ($ClientType -eq 'members') {
    Write-Host "Retrieving Member accounts from Entra ID ..."
    $users = Get-MgBetaUser -Filter "usertype eq 'Member'" -All -Property $szAttributes
} elseif ($ClientType -eq 'guests') {
    Write-Host "Retrieving Guest accounts from Entra ID ..."
    $users = Get-MgBetaUser -Filter "usertype eq 'Guest'" -All -Property $szAttributes
} else {
    Write-Host "Retrieving all user accounts from Entra ID ..."
    $users = Get-MgBetaUser -All -Property $szAttributes
}

ForEach ($user in $users) {
    $usertype = $user.usertype
    $displayname = $user.DisplayName
    $upn = $user.UserPrincipalName
    $companyname = $user.CompanyName
    $signininfo = $user | select -ExpandProperty SignInActivity
    $lastsignin = $signininfo.LastSignInDateTime
    $lastpasswordchangetime = $user.LastPasswordChangeDateTime
    $usercreated = $user.CreatedDateTime
    $OnpremiseLastSync = $user.OnPremisesLastSyncDateTime

    $usr = [pscustomobject]@{UserType=$usertype;UserPrincipalName=$upn;DisplayName=$displayname;CompanyName=$companyname;LastSigninDate=$lastsignin;LastPasswordChangeTime=$lastpasswordchangetime;CreatedDateTime=$usercreated;OnPremiseLastSyncTime=$OnpremiseLastSync}

    $output += $usr
    $usr = ""
    $usertype = ""
    $displayname = ""
    $upn = ""
    $signininfo = ""
    $lastsignin = ""
    $lastpasswordchangetime = ""
    $usercreated = ""
    $OnpremiseLastSync = ""
}

Write-Host "Writing" $users.count "user information to output file"
$output | Export-Csv -Path $OutFile -Delimiter $Delimiter -Encoding UTF8 -Force -NoTypeInformation

Stop-Transcript
