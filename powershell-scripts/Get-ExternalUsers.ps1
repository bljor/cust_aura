<#
.SYNOPSIS
Get-ExternalUsers.ps1 - Exsporterer brugere fra Active Directory der identificeres som eksterne brugere.
Brugere udvælges på baggrund af følgende kriterier:
- Bruger er placeret i OU'en Eksterne (eller en under OU til denne)
- Bruger har Department = Ekstern
- Bruger har en værdi udfyldt i extensionAttribute3

.DESCRIPTION
Dette script finder alle brugere i AD'et som ikke er ansat af AURA, men arbejder for en underleverandør til AURA.

Der er mulighed for at gemme output ved at udfylde parametren -Outfile

.OUTPUTS
Afhængig af parametre returneres forskellige former for output.

Se nærmere under parametrene nedenfor

.PARAMETER Count
Hvis parameter er sat, returnerer scriptet kun antallet af eksterne personer der er identificeret. Der returneres ikke
yderligere oplysninger.

.PARAMETER Outfile
Hvis parameter er sat, eksporteres resultatet af kørslen til den fil som er angivet. Der vises ikke yderligere information på skærmen,
bortset fra at der skrives en status om hvor mange personer der er eksporteret.

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
Creation date:  29-02-2024
Last update:    29-02-2024
#>

param (
    [Parameter(Mandatory=$false)]
    [switch]$Count = $false,
    [Parameter(Mandatory=$false)]
    [string]$Outfile = "",
    [Parameter(Mandatory=$false)]
    [switch]$OverwriteOutfile=$false
)


$extusr = ""
$i = 0
$extUsers = @()

If (($Outfile -ne "") -and (Get-Item $Outfile -ErrorAction SilentlyContinue)) {
    If ($OverwriteOutfile) {
         Remove-Item $Outfile -Force -ErrorAction SilentlyContinue
    } else {
         Write-Host "$Outfile findes allerede, slet filen eller flyt filen til en anden placering"
         Exit
    }
}

Write-Progress -Activity "Finding external users in Active Directory" -Status "Retrieving all users from Active Directory"

$users = Get-AdUser -Filter * -Properties *
$usercount = $users.count

ForEach ($usr in $users) {
    $export = $false
    $i += 1
    $percent = $i / $usercount * 100

    If (($i % 10) -eq 0) {
	    Write-Progress -Activity "Finding external users in Active Directory" -Status "Identifying external people" -PercentComplete $percent
    }

    If ($usr.distinguishedName -like '*OU=Eksterne,*') {$export = $true}
    If ($usr.Department -eq 'Ekstern') { $export = $true }
    If ($usr.extensionAttribute3 -ne $null) { $export = $true }

    If ($export) {
        $lngExpires = $usr.accountExpires
        If (($lngExpires -eq 0) -or ($lngExpires -gt [DateTime]::MaxValue.Ticks)) {
            $accountExpires = "<Aldrig>"
        } else {
            $date = [DateTime]$lngExpires
            $accountExpires = $Date.AddYears(1600).ToLocalTime()
        }
        $extusr = [pscustomobject]@{
            userPrincipalName=$usr.userPrincipalName;
            description=$usr.description;
            extensionAttribute1=$usr.extensionAttribute1;
            extensionAttribute3=$usr.extensionAttribute3;
            department=$usr.department;
            displayName=$usr.displayName;
            mobilePhone=$usr.mobile;
            telephoneNumber=$usr.telephoneNumber;
            title=$usr.title;
            distinguishedName=$usr.distinguishedName;
            whenCreated=$usr.whenCreated;
            whenChanged=$usr.whenChanged;
            PasswordExpired=$usr.PasswordExpired;
            PasswordLastSet=$usr.PasswordLastSet;
            lastLogon=[datetime]::FromFileTime($usr.lastLogon);
            accountExpires=$accountExpires;
            enabled=$usr.enabled
        }
        $extUsers += $extusr
    }
}

Write-Progress -Activity "Finding external users in Active Directory has completed"

If (($Count -eq $false) -and ($Outfile -eq "")) { $extUsers | select description,displayName,userprincipalName }
If ($Count) { Write-Host $extUsers.Count }
If ($Outfile) { $extUsers | Export-Csv -Path $Outfile -NoTypeInformation }
