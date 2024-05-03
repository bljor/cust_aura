#Script to move AD users from Bruger under fratrædelse OU to Disabled OU.

Get-ADUser -Filter 'Disabled -eq "True"' -SearchBase 'OU=Bruger under fratrædelse,OU=AURA users,DC=aura,DC=dk' | Move-ADObject -TargetPath 'OU=Disabled,OU=AURA users,DC=aura,DC=dk' -Verbose

