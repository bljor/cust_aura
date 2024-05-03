Import-Module ActiveDirectory

$date = Get-Date
#$date = $date.AddDays(6)
$begdate = Get-Date -date $date -Format "MMM d"
$dateadd = $date.adddays(14) -as [datetime]
$enddate = Get-Date -date $dateadd -Format "MMM d" 



$SMTPServer = "mailrelay.aura.dk"
$SMTPPort = 25
$Username = "it@aura.dk"

$subject = "Din bruger udløber "




Search-ADAccount -AccountExpiring -TimeSpan "31" | where {$_.Enabled -eq $true} | foreach {

$_.Name

$homep = Get-ADUser $_ -properties homePhone,AccountExpirationdate


$udloeb = $homep.AccountExpirationdate.ToString()

$body = "Din bruger udløber den $udloeb . Kontakt it@aura.dk for at få forlænget tiden. Mvh IT"


$message = New-Object System.Net.Mail.MailMessage

$message.subject = $subject
$message.body = $body
$message.to.add($homep.HomePhone)


$message.from = $username


$smtp = New-Object System.Net.Mail.SmtpClient($SMTPServer, $SMTPPort);
$smtp.EnableSSL = $False
$smtp.send($message)


}
