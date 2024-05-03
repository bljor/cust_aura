$temp = Get-ADComputer -SearchBase "CN=Computers,DC=aura,DC=dk" -Filter 'name -like "AURAPC*"'
if($temp.name) {            
   Add-Content \\aura.dk\services\Deployment\@log\AD\$(get-date -uformat %d-%b-%Y-%H-%M).txt $temp.name
	Get-ADComputer -SearchBase "CN=Computers,DC=aura,DC=dk" -Filter 'name -like "AURAPC*"' | Move-ADObject -TargetPath 'OU=Oestjysk-energi,OU=AuraDK-UsersMoved,OU=Computers,OU=ADMT Migrated Objects,DC=aura,DC=dk'
   } 