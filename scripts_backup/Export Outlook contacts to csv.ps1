Import-Module ActiveDirectory
 
# All of the properties you'd like to pull from Get-ADUser
$properties=@(
    'CN'
    'co'
    'company'
    'mobile'
    'OfficePhone'
    'StreetAddress'
    'postalCode'
    'mail'
    'title'
    'department'
    'l'
    'sAMAccountName'

    )
 
# All of the expressions you want with all of the filtering .etc you'd like done to them
$expressions=@(
    @{Expression={$_.CN};Label="Navn"},
    @{Expression={$_.co};Label="land/område (arbejde)"},
    @{Expression={$_.company};Label="Firma"},
    @{Expression={$_.mobile};Label="Mobiltelefon"},
    @{Expression={$_.mobile};Label="Personsøger"},
    @{Expression={$_.OfficePhone};Label="Telefon (arbejde)"},
    @{Expression={$_.StreetAddress};Label="Gade (arbejde)"},
    @{Expression={$_.postalCode};Label="Postnummer (arbejde)"},
    @{Expression={$_.mail};Label="Mail"},
    @{Expression={$_.title};Label="Stilling"},
    @{Expression={$_.department};Label="Afdeling"},
    @{Expression={$_.l};Label="By (arbejde)"},
    @{Expression={$_.sAMAccountName};Label="Initialer"}
    )
 
$path_to_file = "C:\scripts\users_$((Get-Date).ToString('dd-MM-yyyy_HH-mm-ss')).csv"
 
Get-ADUser -SearchBase "OU=AURA,OU=AURA Users,DC=aura,DC=dk" -LDAPFilter "(&(msRTCSIP-PrimaryUserAddress=sip:*)(!userAccountControl:1.2.840.113556.1.4.803:=2))" -Properties $properties | 
select $expressions | 
Export-CSV $path_to_file -Notypeinformation -Encoding default