

Import-Module ActiveDirectory 

# get alle Users from Domains in forrest

$domains = Get-ADForest oestjysk-energi.dk | Select-Object -ExpandProperty Domains | Sort-Object Domains
Foreach ($domain in $domains){
     Write-Host $domain users
     Write-Host ----------------------------------
     $domainparam = Get-ADDomain -Identity $domain | Select-Object DNSRoot,DistinguishedName,PDCEmulator
     #seperate files pr domain
     Get-ADUser -SearchBase $domainparam.DistinguishedName -Filter * -Server $domainparam.PDCEmulator -Properties * | WHERE-OBJECT {$_.memberof -notlike "CN=grp*"} | 
     Select-Object Enabled,PasswordNeverExpires,lastLogonDate,Created,canonicalName,DistinguishedName,DisplayName,Name,SamAccountName,Initials,Title,EmailAddress,Department | 
     Sort-Object Surname  | 
     Export-Csv c:\Scripts\@Result\AllUsers_$domain.txt -encoding "UTF8" -Delimiter ";" -NoTypeInformation
     } 

$domains = Get-ADForest aura.dk | Select-Object -ExpandProperty Domains | Sort-Object Domains
Foreach ($domain in $domains){
     Write-Host $domain users
     Write-Host ----------------------------------
     $domainparam = Get-ADDomain -Identity $domain | Select-Object DNSRoot,DistinguishedName,PDCEmulator
     #seperate files pr domain
     Get-ADUser -SearchBase $domainparam.DistinguishedName -Filter * -Server $domainparam.PDCEmulator -Properties * | WHERE-OBJECT {$_.memberof -notlike "CN=grp*"} | 
     Select-Object Enabled,PasswordNeverExpires,lastLogonDate,Created,canonicalName,DistinguishedName,DisplayName,Name,SamAccountName,Initials,Title,EmailAddress,Department | 
     Sort-Object Surname  | 
     Export-Csv c:\Scripts\@Result\AllUsers_$domain.txt -encoding "UTF8" -Delimiter ";" -NoTypeInformation
	}
  
  
  
  
  