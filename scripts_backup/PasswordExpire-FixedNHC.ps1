function getBodyText {

$bodyText = @"
Hej $UserName

Dette er blot en information.

Dit password udløber om $length $unit.

Skal du have ændret dit password, så tryk på nedenstående link:
https://account.activedirectory.windowsazure.com/ChangePassword.aspx

Hvis dit password når at udløbe, kan du ikke længere logge ind, og skal have fat i IT for at blive låst op igen.

Med venlig hilsen
IT Afdelingen
Email: it@aura.dk
Tlf: 87 92 55 90
"@

return $bodyText
}


import-module ActiveDirectory;

$enc  = New-Object System.Text.utf8encoding
$maxPasswordAgeTimeSpan = (Get-ADDefaultDomainPasswordPolicy).MaxPasswordAge	
$today = Get-Date
$log = "\\aura.dk\Services\DataExchange\Log\Passwordexpire\" + (get-date -Format ddMMyyyy) + ".txt"
$mailsSent = 0

$users = Get-AdUser -filter 'enabled -eq $true' -Properties Company,PasswordLastSet,PasswordExpired,PasswordNeverExpires,EmailAddress,GivenName,displayName | Sort-Object PasswordLastSet
$users = Get-AdUser ext-bjo -Properties Company,PasswordLastSet,PasswordExpired,PasswordNeverExpires,EmailAddress,GivenName,displayName | Sort-Object PasswordLastSet

ForEach ($user in $users) {

	If ($user.PasswordExpired -eq $false -and $user.PasswordNeverExpires -eq $false) {	# properties beregnes først ved udtræk, så de kan ikke inkluderes i filteret ovenfor
		$UserName = $user.displayname
		$Email = $user.EmailAddress

		$ExpiryDate = $user.PasswordLastSet + $maxPasswordAgeTimeSpan
		$DaysLeft = ($ExpiryDate-$today).days

		$weeks = [int] ($DaysLeft / 7)
		$content = $email + " - " + $DaysLeft
		Add-Content $log -Value ($email + " - " + $DaysLeft)

		If ($weeks -le 4 -and $weeks -gt 1) {
			$unit = "uger"
			$length = $weeks
			$sendmail = $true
		}

		If ($weeks -eq 1) {
			$unit = "uge"
			$length = $weeks
			$sendmail = $true
		}	

		If ($DaysLeft -lt 8 -and $DaysLeft -ge 2) {
			$unit = "dage"
			$length = $DaysLeft
			$sendmail = $true
		}

		If ($DaysLeft -lt 2) {
			$unit = "DAG"
			$length = $DaysLeft
			$sendmail = $true
		}

		$subject = "Dit password udløber om $length $unit"
		$body = getBodyText
	
		If ($sendmail) {
			# Send-MailMessage -Body $body -Encoding $enc -Priority high -SmtpServer mailrelay.aura.dk -To $email -bcc it@aura.dk -From it@aura.dk -Subject $subject
			Write-Host $body
			$mailsSent++
		}
		$sendmail = $false
	}
}
Write-Host $mailsSent "emails sent"
