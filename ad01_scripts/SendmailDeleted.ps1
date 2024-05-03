# Anvendes sammen med en Scheduled Task der trigges af en bestemt Event i loggen.


get-eventlog -InstanceId 4726 -LogName Security -Newest 1 | Export-Csv c:\temp\userdeleted.txt
$body = Get-Content -Path c:\temp\userdeleted.txt | Out-String 
Send-MailMessage -BodyAsHtm -Attachments "c:\temp\userdeleted.txt" -Priority high -SmtpServer mailrelay.aura.dk -To  it@aura.dk -From it@aura.dk -Subject "Bruger slettet" -Body $body