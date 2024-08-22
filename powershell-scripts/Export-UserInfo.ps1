<#
.SYNOPSIS
Export-UserInfo.ps1 - Eksporterer information om brugere til en CSV fil.
Der udsøges brugere fra Active Directory og tilføjes nogle ekstra properties i udtrækket.
Dato for udløb af password beregnes ud fra datoen for hvornår brugeren sidst har ændret sit password, og så den frekvens der er defineret i Domain Security Policy.

DESCRIPTION
Dette script finder alle brugere i Active Directory og eksporterer information om brugerne til en CSV fil.

Scriptet er lavet til opfyldelse af et engangsbehov, men kan scheduleres via en scheduled task - så det løbende (eks. dagligt) eksporterer gældende information.

.OUTPUTS
Der vises ikke noget output på skærmen, men resultatet skrives til filen der angives i parameteren -outfile

.PARAMETER OutFile
Angiver hvilken fil resultatet skal skrives til. Hvis der ikke angives en fuld sti, så skrives der til samme folder som scriptet afvikles fra.

Hvis parameter ikke angives, så skrives til c:\temp\user-export.csv

.PARAMETER Delimiter
Angiver hvilken seperator der anvendes til at adskille de forskellige værdier i eksporten.

Hvis parameter ikke specificeres, så anvendes som standard semikolon (;)

.EXAMPLE
.\Export-UserInfo.ps1 -outfile c:\temp\user-export.csv


.NOTES
Version:	1.0
Author:		Brian Lie Jørgensen (brian@wipe.dk)
For:		AURA
Creation date:	(original date unknown, created by Aura)
Last update:	20/06/2024

Change Log:
v1.0	20/06/2024		- NHC, Brian Lie Jørgensen
#>

param (
	[Parameter(Mandatory=$false)]
	[string]$OutFile = "c:\temp\user-export.csv",
	[Parameter(Mandatory=$false)]
	[char]$Delimiter = ";"
)

Import-Module ActiveDirectory;

$output = @()
$today = Get-Date

$users = Get-AdUser -Filter * -Properties *

ForEach ($user in $users) {
	If ($user.lastLogonTimestamp -eq $null) {
		$lastLogonTimeStamp = "never"
	} else
	{
		$lastLogonTimeStamp = [datetime]::FromFileTime($user.lastLogonTimestamp)
	}
	$ae = $user.accountExpires
	
	If (($ae -eq 9223372036854775807) -or ($ae -eq 0)) {
		$ae = "never"
	} else 
	{
		$ae = [datetime]::FromFileTime($ae)
	}
	
	$lockouttime = $user.lockoutTime

	If (($lockouttime -eq 9223372036854775807) -or ($lockouttime -eq 0)) {
		$lockouttime = "never"
	} else
	{
		$lockouttime = [datetime]::FromFileTime($lockouttime)
	}
	$usr = [pscustomobject]@{
		GivenName=$user.GivenName;
		Surname=$user.sn;
		Initials=$user.Initials;
		Mail=$user.mail;
		SamAccountName=$user.SamAccountName;
		UserPrincipalName=$user.UserPrincipalName;
		MailNickname=$user.mailNickname;
		DisplayName=$user.DisplayName;
		DistinguishedName=$user.DistinguishedName;
		Title=$user.Title;
		Company=$user.Company;
		Organization=$user.Organization;
		Office=$user.Office;
		StreetAddress=$user.StreetAddress;
		City=$user.City;
		Country=$user.Country;
		Department=$user.Department;
		Description=$user.Description;
		EmailAddress=$user.EmailAddress;
		Mobile=$user.mobile;
		OfficePhone=$user.OfficePhone;
		Manager=$user.Manager;
		extensionAttribute1=$user.extensionAttribute1;
		extensionAttribute2=$user.extensionAttribute2;
		extensionAttribute3=$user.extensionAttribute3;
		extensionAttribute4=$user.extensionAttribute4;
		UserAccountExpires=$ae;
		PasswordExpired=$user.PasswordExpired;
		PasswordLastSet=$user.PasswordLastSet;
		PasswordNeverExpires=$user.PasswordNeverExpires;
		PasswordNotRequired=$user.PasswordNotRequired;
		LockedOut=$user.LockedOut;
		LockoutTime=$lockouttime;
		LastLogonTimestamp=$lastLogonTimeStamp;
		CannotChangePassword=$user.CannotChangePassword;
		AdminCount=$user.adminCount;
		CreateTimeStamp=$user.createTimeStamp;
		ChangedTimeStamp=$user.whenChanged
	}
	$output += $usr
}

$output | Export-Csv -Delimiter $Delimiter -Path $OutFile -Encoding UTF8 -NoTypeInformation -Force
