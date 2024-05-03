# Finder alle AURA brugere.
$users = Get-CsAdUser -OU 'aura.dk/AURA Users/AURA' 
# Finder alle i SfB.Office.Users
$SfBOfficeUsers = Get-ADGroupMember -Identity 'SfB.Office.Users' -Recursive | Select -ExpandProperty SamAccountName

$taeller = 0
$antalusers = $users.count

# Sletter ORGadusers variablen hvis den findes.
if($ORGadusers)
    {
        Clear-Variable ORGadusers 
    }
# Finder alle Org * Grupper i ADet
$groups = get-adgroup -Filter {(name -like "ORG*") -or (name -like "Grp.IPPhone")}
$antalORGgrupper = $groups.count   
# Finder alle bruger i ORG grupper og gemmer medlemmer i en variable.
foreach($Group in $Groups)
    {
        $groupname = $Group.Name
        $taeller++
        $percentComplete = ($taeller / $antalORGgrupper) * 100
        Write-Progress -Activity 'Finder Brugere i ORG Grupper' -Status " $taeller / $antalORGgrupper - $Groupname " -PercentComplete $percentComplete
        $ORGaduserstemp = Get-ADGroupMember -Id $Group | Where { $_.objectClass -eq "user" } 
        $ORGadusers = $ORGadusers + $ORGaduserstemp
    }

$taeller = 0
# Looper alle brugerne igennem
ForEach ($user in $users)
{
    $taeller++
    $percentComplete = ($taeller / $antalusers) * 100
    $displaynavn = $user.DisplayName
    Write-Progress -Activity 'Checker om brugeren skal Skype enables/disables' -Status "  $taeller / $antalusers - $displaynavn " -PercentComplete $percentComplete
    #Checker om brugeren er i en ORG Gruppe.
       
    #Hvis der er en ORG gruppe så. 
    if ($ORGadusers.SamAccountName -contains $user.SamAccountName) 
        {   
            # Har brugeren ikke en sip addresse så enables han til skype.
            if($user.sipAddress -notlike 'sip*')    
                {
                Enable-CsUser $user.Identity -RegistrarPool 'SfB-Front01.aura.dk' -SipAddressType emailaddress
                Write-Host "Enabler" $user.WindowsEmailAddress
                # Venter 20 sec så brugeren er oprette i skype.
                sleep 20 
                }
        }

    # Henter brugerens Skype infomation
    $skypeinfo = get-csuser $user.Identity 
    # hvis brugeren er i SfB.Office.Users gruppen
    If ($SfBOfficeUsers -contains $user.SamAccountName) 
        {
            # Checker for om brugeren allerde er EnterpriseVoiceEnabled, hvis ikke sætten den til true.
            if ($skypeinfo.EnterpriseVoiceEnabled -ne $true) 
                {
                    Write-Host "Sætter EnterpriseVoiceEnabled " $user.Name    
                    Set-CsUser -Identity $skypeinfo.SipAddress -EnterpriseVoiceEnabled $true 
                }

         } 
   # Hvis brugeren ikke er i SfB.Office.Users gruppen
   Else 
        {
            # Checker for om brugeren er EnterpriseVoiceEnabled, hvis ja fjernes den.
            if ($skypeinfo.EnterpriseVoiceEnabled -eq $true) 
                {
                    Write-Host "fjerner EnterpriseVoiceEnabled " $user.Name    
                    Set-CsUser -Identity $skypeinfo.SipAddress -EnterpriseVoiceEnabled $false
                }
        }

}



# Henter alle skype brugere
$users = Get-CsUser

ForEach ($user in $users)
    {
        # Checker for om man er i en ORG Gruppe, hvis ikke disables man i Skype.
        if ($ORGadusers.SamAccountName -notcontains $user.SamAccountName) 
                {
                    write-host "ingen ORG gruppe, disabler Skype brugeren."
                    write-host $user.SamAccountName
                    Disable-CsUser -Identity $user.SamAccountName
                }
    }

