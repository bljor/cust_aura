import-module ActiveDirectory;
$enc  = New-Object System.Text.utf8encoding
$maxPasswordAgeTimeSpan = (Get-ADDefaultDomainPasswordPolicy).MaxPasswordAge

Get-ADUser -filter 'enabled -eq $true' -properties company, PasswordLastSet, PasswordExpired, PasswordNeverExpires, EmailAddress, GivenName,displayname | Sort-Object PasswordLastSet| foreach {

    $today=get-date
    $log = "\\aura.dk\Services\DataExchange\Log\Passwordexpire\" + (get-date -Format ddMMyyyy) + ".txt"
    $UserName=$_.displayname
    $Email=$_.EmailAddress

    if (!$_.PasswordExpired -and !$_.PasswordNeverExpires) 
    {
 
        $ExpiryDate=$_.PasswordLastSet + $maxPasswordAgeTimeSpan
        $DaysLeft=($ExpiryDate-$today).days

			if ($DaysLeft -eq 28)
			    {	
                    ForEach ($email in $_.EmailAddress) { 
                    $content = $email + " - " + $DaysLeft
                    Add-content $log -Value $content
				    Send-MailMessage -BodyAsHtm -Encoding $enc -Priority high -SmtpServer mailrelay.aura.dk -To $email -bcc it@aura.dk -From it@aura.dk -Subject "Dit password udløber om 4 Uger" -Body "<style>p{font-family: verdana;}<body><p>Hej $UserName <br><br>Dette er blot en infomation.<br><br>Dit password udløber om 4 Uger.<br><br>Skal du have ændret dit password, så tryk på nedenstående link:<br>https://account.activedirectory.windowsazure.com/ChangePassword.aspx<br><br>Hvis dit password når at udløbe, kan du ikke længere logge ind, og skal have fat i IT for at blive låst op igen.<br><br>Med Venlig Hilsen <br>IT Afdelingen<br>Email:  it@aura.dk<br>Tlf: 87 92 55 90" 
				    }
 			    }

            if ($DaysLeft -eq 21)
			    {	
                    
				    ForEach ($email in $_.EmailAddress) { 
                    $content = $email + " - " + $DaysLeft
                    Add-content $log -Value $content
				    Send-MailMessage -BodyAsHtm -Encoding $enc -Priority high -SmtpServer mailrelay.aura.dk -To $email -bcc it@aura.dk -From it@aura.dk -Subject "Dit password udløber om 3 Uger" -Body "<style>p{font-family: verdana;}<body><p>Hej $UserName <br><br>Dette er blot en infomation.<br><br>Dit password udløber om 3 Uger.<br><br>Skal du have ændret dit password, så tryk på nedenstående link:<br>https://account.activedirectory.windowsazure.com/ChangePassword.aspx<br><br>Hvis dit password når at udløbe, kan du ikke længere logge ind, og skal have fat i IT for at blive låst op igen.<br><br>Med Venlig Hilsen <br>IT Afdelingen<br>Email:  it@aura.dk<br>Tlf: 87 92 55 90" 
				    }
 			    }

            if ($DaysLeft -eq 14)
			    {	
				    ForEach ($email in $_.EmailAddress) { 
                    $content = $email + " - " + $DaysLeft
                    Add-content $log -Value $content
				    Send-MailMessage -BodyAsHtm -Encoding $enc -Priority high -SmtpServer mailrelay.aura.dk -To $email -bcc it@aura.dk -From it@aura.dk -Subject "Dit password udløber om 2 Uger" -Body "<style>p{font-family: verdana;}<body><p>Hej $UserName <br><br>Dette er blot en infomation.<br><br>Dit password udløber om 2 Uger.<br><br>Skal du have ændret dit password, så tryk på nedenstående link:<br>https://account.activedirectory.windowsazure.com/ChangePassword.aspx<br><br>Hvis dit password når at udløbe, kan du ikke længere logge ind, og skal have fat i IT for at blive låst op igen.<br><br>Med Venlig Hilsen <br>IT Afdelingen<br>Email:  it@aura.dk<br>Tlf: 87 92 55 90" 
				    }
 			    }
             if ($DaysLeft -lt 7)
			    {	
				    ForEach ($email in $_.EmailAddress) { 
                    $content = $email + " - " + $DaysLeft
                    Add-content $log -Value $content
				    Send-MailMessage -BodyAsHtm -Encoding $enc -Priority high -SmtpServer mailrelay.aura.dk -To $email -bcc it@aura.dk -From it@aura.dk -Subject "Dit password udløber om $DaysLeft dage" -Body "<style>p{font-family: verdana;}<body><p>Hej $UserName <br><br>Dette er blot en infomation.<br><br>Dit password udløber om $DaysLeft dage.<br><br>Skal du have ændret dit password, så tryk på nedenstående link:<br>https://account.activedirectory.windowsazure.com/ChangePassword.aspx<br><br>Hvis dit password når at udløbe, kan du ikke længere logge ind, og skal have fat i IT for at blive låst op igen.<br><br>Med Venlig Hilsen <br>IT Afdelingen<br>Email:  it@aura.dk<br>Tlf: 87 92 55 90" 
				    }
 			    }
	}
 }
