<#
.SYNOPSIS
Get-LocalAdministrators.ps1 - Logger eventuelle brugere og grupper, som er medlem af den lokale Administrators gruppe på en PC eller server.
Hvis der findes andre end Domain Admins, LocalAdmin_Super, samt den indbyggede Administrator konto - så logges information om de uventede
brugere og grupper til en fil som skrives til folderen \\aura.dk\services\DataExchange\LocalAdmin.

Hvis filen findes i forvejen, så overskrives den med de aktuelle oplysninger.

Hvis filen findes, og der ikke er noget at rapportere på computeren, så slettes den centrale fil.

På en computer kan den lokale administrator bruger identificeres ved, at SID altid begynder med S-1-5- og slutter med -500. Det er dette der
gør at eks. administrator SID og guest SID kaldes "well-known" accounts.

Det samme gør sig gældende for den lokale Administrators gruppe (eller Administratorer). Den har altid SID S-1-5-32-544.

Derfor findes medlemmer med Get-LocalGroupMember -SID S-1-5-32-544.

Med Get-LocalGroupMember returneres både medlemmer fra Active Directory, samt lokalt oprettede elementer. Det er muligt at filtrere
på dette via PrincipalSource (hvis det ønskes). I dette script er der ikke filtreret på lokale og domæne elementer.

Eks. på filtrering
Get-LocalGroupMember -SID S-1-5-32-544 | Where-Object {$_.PrincipalSource -eq 'Local'}

.DESCRIPTION
Dette script logger uventet indhold af den lokale Administrators gruppe på PC'er og servere til en central placering.
Filen navngives med hostnavnet på den enhed, hvorfra scriptet afvikles.

.OUTPUTS
Hvis der ikke identificeres uønskede medlemmer af Administrators gruppen, så logges ingenting.

Findes der uønskede medlemmer, så skrives indhold til en central fil plceret på \\aura.dk\services\DataExchange\LocalAdmin\[hostname].txt

.EXAMPLE
Get-LocalAdministrators.ps1


.NOTES
Version:        1.0
Author:         Brian Lie Jørgensen (nhc)
For:            AURA
Creation date:  29-02-2024
Last update:    04-03-2024

#>

$export = @()

# Skriv til en fil på en central server, der skrives én fil pr. host - og filen overskrives med nyeste information - hvis
# der er brugere som har uventet adgang. Hvis der kun er godkendte brugere / grupper med Lokal Administrator adgang, så slettes
# den centrale fil - således der ikke er noget at kigge på.
$folder = "\\aura.dk\services\DataExchange\LocalAdmin\"
$file = $ENV:COMPUTERNAME + ".txt"
$outfile = $folder + $file

# Administrators gruppens SID
$members = Get-LocalGroupMember -SID S-1-5-32-544
$output = $false

ForEach ($member in $members) {
    $sid = $member.sid.value

    If (($sid -like 'S-1-5-*') -and ($sid -like '*-500')) { }    # Local default administrator account, den er OK
    elseIf ($member.Name -eq "AURA\Domain Admins") { }			# Domain Admins er OK
    elseIf ($member.Name -eq "AURA\LocalAdmin_Super") { }		# Denne er også OK, centralt styret grupper der kan tildele adgang hvis nødvendigt
    else {							                            # Uventet adgang, skal logges centralt 
        $person = [pscustomobject]@{Name=$member.Name;PrincipalSource=$member.PrincipalSource;ObjectClass=$member.ObjectClass;SID=$member.SID;Computer=$ENV:COMPUTERNAME}
	    $export += $person
	    $output = $true
    }
}

If ($output) {
    $export | export-csv -path $outfile -force -NoTypeInformation
} else {    # Ingenting at eksportere, slet den centrale fil, hvis den findes.
    $itm = Get-ChildItem $outfile -ErrorAction SilentlyContinue
    Remove-Item -Path $outfile -Force
}
