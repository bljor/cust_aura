Import-Module ActiveDirectory

Search-ADAccount -SearchBase "OU=Eksterne,OU=AURA Users,DC=aura,DC=dk" -AccountInactive -TimeSpan ([timespan]300d) -UsersOnly | Set-ADUser -Enabled $false -WhatIf