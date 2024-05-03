# Sætter extensionAttribute9=Disabled på brugere under Disabled OUen

Get-ADUser -filter * -searchbase "OU=Disabled,OU=AURA Users,DC=aura,DC=dk" | Set-ADUser -Replace @{extensionAttribute9="Disabled"}

$users = get-aduser -filter {extensionAttribute9 -eq 'Disabled'} -properties extensionAttribute9

ForEach ($user in $users)
{
	if($user.DistinguishedName -Like "*OU=Disabled,OU=AURA Users,DC=aura,DC=dk")
		{
		}
	else
		{
			# Fjerner extensionAttribute9=Disabled på brugere der ikke er i Disabled OUen
			Write-Host "Not Member"
			Set-ADUser -Identity $user.SamAccountName -clear extensionAttribute9
		}
}



# Skjuler brugere under Disabled OUen fra Global address listen.
Get-ADUser ` -Filter {(enabled -eq "false") -and (msExchHideFromAddressLists -notlike "*")} ` -SearchBase "OU=Disabled,OU=AURA Users,DC=aura,DC=dk"` -Properties enabled,msExchHideFromAddressLists |  Set-ADUser -Add @{msExchHideFromAddressLists="TRUE"} 