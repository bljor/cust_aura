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

function getBodyTextExternal {

$bodyTextExternal = @"
Hej $UserName

Dette er blot en information.

Dit password hos Aura udløber om $length $unit.

Hvis dit password når at udløbe, så kan du ikke længere logge ind.

Tag kontakt til IT for at få opdateret dit password.

Med venlig hilsen
IT Afdelingen
Email: it@aura.dk
Tlf: 87 92 55 90
"@

return $bodyTextExternal

}

import-module ActiveDirectory;

$debugrun = $false
$enc  = New-Object System.Text.utf8encoding
$maxPasswordAgeTimeSpan = (Get-ADDefaultDomainPasswordPolicy).MaxPasswordAge	
$today = Get-Date
$log = "\\aura.dk\Services\DataExchange\Log\Passwordexpire\" + (get-date -Format ddMMyyyy) + ".txt"
$mailsSent = 0

$externalIdentificatorAttribute = 'extensionAttribute3'			# The attribute on the user which identifies that this is an external user account
$queryFilter = $externalIdentificatorAttribute + " -like '*'"
$userProperties = 'Company','PasswordLastSet','PasswordExpired','PasswordNeverExpires','EmailAddress','GivenName','displayName','extensionAttribute3'

$queryFilter = 'enabled -eq $true'
If ($debugRun) {
	$users = Get-AdUser ext-bjo -Properties $userProperties | Sort-Object PasswordLastSet
} else {
	$users = Get-AdUser -filter $queryFilter -Properties $userProperties | Sort-Object PasswordLastSet
}

$sendmail = $false
ForEach ($user in $users) {

	If ($user.PasswordExpired -eq $false -and $user.PasswordNeverExpires -eq $false) 	# properties beregnes først ved udtræk, så de kan ikke inkluderes i filteret ovenfor
	{
		$UserName = $user.displayname
		$Email = $user.EmailAddress
		If ($email -eq $nothing)
		{
			$email = $user.userprincipalName
		}

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

		If ($debugrun) { $sendmail = $true }
	
		If ($sendmail) {

			# Eksterne brugere identificeres ved at have en værdi i en specifik attribut i AD'et. Er det en ekstern bruger sendes en anden besked, og beskeden
			# sendes til en ekstern mailadresse fremfor til en Aura adresse.
			If ($user.$externalIdentificatorAttribute) {
				$subject = "Dit password til AURA udløber om $length $unit"
				$body = getBodyTextExternal
				$email = $user.extensionAttribute3
			} else {
				$subject = "Dit password udløber om $length $unit"
				$body = getBodyText
				$Email = $user.EmailAddress
				If ($email -eq $nothing)
				{
					$email = $user.userprincipalName
				}
			}

			If ($debugRun) {
				$email = "ext-bjo@aura.dk"
				Write-Host "Subject: " $Subject
				Write-Host $body
			} else {
				#Send-MailMessage -Body $body -Encoding $enc -Priority high -SmtpServer mailrelay.aura.dk -To $email -bcc it@aura.dk -From it@aura.dk -Subject $subject
				$mailsSent++
				Write-Host $subject
				Write-Host "Send mail to" $email
			}

			$sendmail = $false
		}
	}
}
Write-Host $mailsSent "emails sent"
