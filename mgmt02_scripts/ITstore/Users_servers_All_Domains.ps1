
# get alle servers from Domains in forrest

Import-Module ActiveDirectory 

$domains = Get-ADForest oestjysk-energi.dk | Select-Object -ExpandProperty Domains | Sort-Object Domains
Foreach ($domain in $domains){
     Write-Host $domain servers
     Write-Host ----------------------------------
     $domainparam = Get-ADDomain -Identity $domain | Select-Object DNSRoot,DistinguishedName,PDCEmulator
     #seperate files pr domain
     Get-ADComputer -SearchBase $domainparam.DistinguishedName -Filter {OperatingSystem -Like "*Server*"} -Server $domainparam.PDCEmulator -Properties * | 
     Select-Object Name, OperatingSystem, DNSHostName, lastLogonDate,IPv4Address , whenCreated, canonicalName, enabled,Description |
     Export-Csv \\aura.dk\services\Deployment\@ADserverlists\ADcomputer_$domain.txt -encoding "UTF8" -Delimiter ";" -NoTypeInformation
     } 


$domains = Get-ADForest aura.dk | Select-Object -ExpandProperty Domains | Sort-Object Domains
Foreach ($domain in $domains){
     Write-Host $domain servers
     Write-Host ----------------------------------
     $domainparam = Get-ADDomain -Identity $domain | Select-Object DNSRoot,DistinguishedName,PDCEmulator
     #seperate files pr domain
     Get-ADComputer -SearchBase $domainparam.DistinguishedName -Filter {OperatingSystem -Like "*Server*"} -Server $domainparam.PDCEmulator -Properties * | 
     Select-Object Name, OperatingSystem, DNSHostName, lastLogonDate,IPv4Address , whenCreated, canonicalName, enabled, Description |
     Export-Csv \\aura.dk\services\Deployment\@ADserverlists\ADcomputer_$domain.txt -encoding "UTF8" -Delimiter ";" -NoTypeInformation
	}
  
  
  
  
# get alle Users from Domains in forrest

$domains = Get-ADForest oestjysk-energi.dk | Select-Object -ExpandProperty Domains | Sort-Object Domains
Foreach ($domain in $domains){
     Write-Host $domain users
     Write-Host ----------------------------------
     $domainparam = Get-ADDomain -Identity $domain | Select-Object DNSRoot,DistinguishedName,PDCEmulator
     #seperate files pr domain
     Get-ADUser -SearchBase $domainparam.DistinguishedName -Filter * -Server $domainparam.PDCEmulator -Properties * | WHERE-OBJECT {$_.memberof -like "CN=grp*"} | 
     Select-Object DistinguishedName,lastLogonDate,DisplayName,Name,SamAccountName,Initials,Title,EmailAddress,HomePhone,MobilePhone,ipPhone,OfficePhone,Department,Organization,HomePage,Enabled | 
     Sort-Object Surname  | 
     Export-Csv \\aura.dk\services\Deployment\@ADserverlists\AllUsers_$domain.txt -encoding "UTF8" -Delimiter ";" -NoTypeInformation
     } 

$domains = Get-ADForest aura.dk | Select-Object -ExpandProperty Domains | Sort-Object Domains
Foreach ($domain in $domains){
     Write-Host $domain users
     Write-Host ----------------------------------
     $domainparam = Get-ADDomain -Identity $domain | Select-Object DNSRoot,DistinguishedName,PDCEmulator
     #seperate files pr domain
     Get-ADUser -SearchBase $domainparam.DistinguishedName -Filter * -Server $domainparam.PDCEmulator -Properties * | WHERE-OBJECT {$_.memberof -like "CN=grp*"} | 
     Select-Object DistinguishedName,lastLogonDate,DisplayName,Name,SamAccountName,Initials,Title,EmailAddress,HomePhone,MobilePhone,ipPhone,OfficePhone,Department,Organization,HomePage,Enabled | 
     Sort-Object Surname  | 
     Export-Csv \\aura.dk\services\Deployment\@ADserverlists\AllUsers_$domain.txt -encoding "UTF8" -Delimiter ";" -NoTypeInformation
	}
  
  
  
  
  