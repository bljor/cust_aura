Import-Module ActiveDirectory

Get-ADUser -Filter {Enabled -eq $True} -SearchBase "OU=Eksterne,OU=AURA Users,DC=aura,DC=dk" -Properties Name,SamAccountName,LastLogonDate,memberof |
Where {($_.LastLogonDate -lt (Get-Date).AddDays(-44)) -and ($_.LastLogonDate -ne $NULL) -and ($_.memberOf -like "CN=Grp.VPNEksterne,OU=AURA Groups,DC=aura,DC=dk")} |
Set-ADUser -Enabled $false

# Til test :)
#Sort LastLogonDate |
#ft Name,SamAccountName,LastLogonDate -AutoSize |
#Out-File C:\temp\InaktiveBrugere.txt 
#$body = Get-Content -Path c:\temp\InaktiveBrugere.txt | Out-String 
#Send-MailMessage -BodyAsHtm -Attachments "c:\temp\InaktiveBrugere.txt" -SmtpServer smtprelay.aura.dk -To  wit@aura.dk -From it@aura.dk -Subject "Inaktive brugere"