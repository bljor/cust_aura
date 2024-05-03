$Secure2 = Get-Content c:\scripts\VPN_Encrypted.txt
$pass = $Secure2 | ConvertTo-SecureString
$Ptr = [System.Runtime.InteropServices.Marshal]::SecureStringToCoTaskMemUnicode($pass)
$decrypted = [System.Runtime.InteropServices.Marshal]::PtrToStringUni($Ptr)
cmd.exe /c  "c:\scripts\putty.exe -load Firewall -l Info -pw $decrypted -m c:\scripts\VPN.txt"


$body = "<head><meta http-equiv=refresh content=120></head><html><style>body {
  background-color: #101010;

}
h1 {
  color: #ffffff;
}

tr:nth-child(even) 
{
	background: #CCC;
	font-size: 36px;}
tr:nth-child(odd) 
{
	background: #FFF;
	font-size: 36px;} </style><body><table><tr><th>User</th><th>Time</th></tr>"

foreach($line in Get-Content c:\scripts\putty.log) {
    if($line -match "Username     :")
        {
            $body += "<tr><td>" + ($line -split ' ')[6] + "</td>"
        }
    if($line -match "Duration ")
        {
            $body += "<td>" + ($line -split ' ')[6] + "</td></tr>"
        }
} 

$body += "</table></body>"

$body | Out-file \\mgmt01.aura.dk\wwwroot\vpn.htm