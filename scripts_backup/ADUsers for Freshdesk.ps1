Get-AdGroup -filter * | Where {$_.name -like "ORG *"} | Get-ADGroupMember | Get-ADUser -Properties * | select name,EmailAddress,City,MobilePhone,OfficePhone,Created | Export-Csv "\\aura.dk\filer\Stab\Shared Service\IT\Administrativt\Kontaktliste\ADUsers.csv" -Encoding UTF8 -NoTypeInformation
$configFiles = Get-ChildItem *.csv -rec -Path "\\aura.dk\filer\Stab\Shared Service\IT\Administrativt\Kontaktliste\"
$count = 0
foreach ($file in $configFiles)
    {
        $tempo = (Get-Content $file.PSPath)  
        if ($tempo -like '*"*')
            {
                $count++
                (Get-Content $file.PSPath) | 
                Foreach-Object { $_ -replace '"', '' } |
                set-Content $file.PSPath
            }
    }
$count