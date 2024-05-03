$anonUsername = "anonymous"
$anonPassword = ConvertTo-SecureString -String "anonymous" -AsPlainText -Force
$anonCredentials = New-Object System.Management.Automation.PSCredential($anonUsername,$anonPassword)

Get-ChildItem "\\aura.dk\DAX\DAXarkiv\DAXNET\DataUdveksling\Aflaesninger\Energistyring"| Where {-NOT $_.PSIsContainer} | foreach {$_.fullname} |
send-mailmessage -from "noreply@aura.dk" -to "ediel_omega@aura.dk"  -subject "Energistyring" -smtpServer smtprelay.aura.dk -credential $anonCredentials
Move-Item \\aura.dk\DAX\DAXarkiv\DAXNET\DataUdveksling\Aflaesninger\Energistyring\*.csv \\aura.dk\DAX\DAXarkiv\DAXNET\DataUdveksling\Aflaesninger\Energistyring\arkiv

exit