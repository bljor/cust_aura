$password = read-host -prompt "Enter your Password" 
write-host "$password is password" 
$secure = ConvertTo-SecureString $password -force -asPlainText 
$bytes = ConvertFrom-SecureString $secure 
$bytes | out-file c:\scripts\Kamstrup\KamstrupFTP_Encrypted.txt 
