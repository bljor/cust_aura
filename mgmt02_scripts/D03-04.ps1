$Secure2 = Get-Content c:\scripts\VPN_Encrypted.txt
$pass = $Secure2 | ConvertTo-SecureString
$Ptr = [System.Runtime.InteropServices.Marshal]::SecureStringToCoTaskMemUnicode($pass)
$decrypted = [System.Runtime.InteropServices.Marshal]::PtrToStringUni($Ptr)
$user = 'sdkadmin'
    $Url = "https://db-sql-2017-hot.aura.dk/ReportServer?%2fD04&rs:Command=Render&rv:Toolbar=false%20instead%20of%20&rc:Toolbar=false"
    $Path = "\\prtg.aura.dk\public\D03.htm"

$WebClient = New-Object System.Net.WebClient
$WebClient.Credentials = New-Object System.Net.Networkcredential($user, $decrypted)
$WebClient.DownloadFile( $url, $path )

