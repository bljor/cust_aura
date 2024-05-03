get-eventlog -InstanceId 4720 -LogName Security -Newest 1 | Export-Csv c:\temp\usercreated.txt
$body = Get-Content -Path c:\temp\usercreated.txt | Out-String 
Send-MailMessage -BodyAsHtm -Attachments "c:\temp\usercreated.txt" -Priority high -SmtpServer mailrelay.aura.dk -To  it@aura.dk -From it@aura.dk -Subject "Bruger oprettet" -Body $body