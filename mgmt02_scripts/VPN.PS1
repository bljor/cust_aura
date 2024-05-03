$SecurePass = Get-Content c:\scripts\VPN_Encrypted.txt
$pass = $SecurePass | ConvertTo-SecureString 

$Ptr = [System.Runtime.InteropServices.Marshal]::SecureStringToCoTaskMemUnicode($pass)
$decrypted = [System.Runtime.InteropServices.Marshal]::PtrToStringUni($Ptr)
[System.Runtime.InteropServices.Marshal]::ZeroFreeCoTaskMemUnicode($Ptr)
cmd.exe /c  "c:\scripts\putty.exe -load Firewall -l VPNInfo -pw $decrypted -m c:\scripts\VPN.txt"

$puttylog  = "c:\scripts\putty.log-temp"
$puttylog_old = "c:\scripts\putty.log-temp_old"


$body_e = "<head><meta http-equiv=refresh content=800></head><html><style>body {
  background-color: #ffffff;
}
h1 {
  color: #000000;
}
tr:nth-child(even) 
{
	background: #CCC;
	font-size: 36px;}
tr:nth-child(odd) 
{
	background: #FFF;
	font-size: 36px;} </style><body><font size=36 color=#000000>Eksterne VPN Brugere</font><table><tr><th>User</th><th><font size=3>Country</font></th><th>Download</th><th>Upload</th><th>Time</th></tr>"


$body = "<head><meta http-equiv=refresh content=800></head><html><style>body {
  background-color: #ffffff;
}
h1 {
  color: #000000;
}
tr:nth-child(even) 
{
	background: #CCC;
	font-size: 36px;}
tr:nth-child(odd) 
{
	background: #FFF;
	font-size: 36px;} </style><body><font size=36 color=#000000>Interne VPN Brugere<table><tr><th>User</th><th><font size=3>Country</font></th><th>Download</th><th>Upload</th><th>Time</th></tr>"

$file = "\\mgmt01.aura.dk\prtg\vpn.htm"
$file_e = "\\mgmt01.aura.dk\prtg\vpn_e.htm"


get-content c:\scripts\putty.log | select -Skip 16 | set-content "c:\scripts\putty.log-temp"
#move "c:\scripts\putty.log-temp" c:\scripts\putty.log -Force


foreach ($line in Get-Content c:\scripts\putty.log-temp) {
    if ($line -match "Username     :") {
        $user = ($line.toupper() -split ' ')[6]
        $user = $user | Foreach { $_ -replace "\@aura.dk", "" } | Foreach { $_ -replace "\@dinel.dk", "" } | Foreach { $_ -replace "AURA\\", "" } 
        $group = "Grp.VPNEksterne" 
        $members = Get-ADUser -Filter * -SearchBase "OU=Eksterne,OU=AURA Users,DC=aura,DC=dk" | select SamAccountName
   
        If ($members.SamAccountName -contains $user) {
            $e = "True"
            $body_e += "<tr><td>" + $user 
            $body_e += "<font size=5><b>[e]</b></font></td>"
        }
        Else {
            $e = "false"
            $body += "<tr><td>" + $user 
            $body += "</td>"
        }
    }

    if ($line -match "Public IP") {
        $temp = ($line -split ":")
        $ip = $temp[2]
        if (($ip.StartsWith(" 192.168.8.")) -or ($ip.StartsWith(" 192.168.9."))) {
            if ($e -eq "True") {
                $body_e += "<td><center><img src=https://mgmt01.aura.dk/prtg/wifi.png height=20></td>" 
            }
            else {
                $body += "<td><center><img src=https://mgmt01.aura.dk/prtg/wifi.png height=20></td>" 
            }
        }

        else {

            $csvFile = Import-Csv c:\scripts\ip.csv
            $ip = $ip.replace(' ', '')
            if ($ip -in $csvFile.ip) {
                $country = $csvFile | where-object ip -eq $ip
                $flag = $country.country
            }
            else {
                $request = "https://ipinfo.io/" + $temp[2] + "/country"
                $flag = Invoke-WebRequest $request
                $flag = $flag.country_flag.ToString()
                $flag = $flag -replace "`n", "" -replace "`r", ""
                #    $body += "<td><center><img src=" + $flag + " height=20></td>"
                $newip = "`n" + $ip + "," + $flag  
                add-content c:\scripts\ip.csv $newip

            }


            if ($e -eq "True") {
                $body_e += "<td><center><img src=https://www.countryflags.io/" + $flag + "/shiny/16.png height=20></td>" 
            }
            else {
                $body += "<td><center><img src=https://www.countryflags.io/" + $flag + "/shiny/16.png height=20></td>"  
            }
        }
	}
                   

            

    if ($line -match "Bytes Tx") {
      
        $temp = ($line -split ":")
        $temp2 = ($temp[1] -replace "[^0-9]" , '')
        $temp2 = ($temp2 / 1024 / 1024) 
        $temp1 = ([math]::round($temp2))
        if ($temp1 -gt '1000') {
            $color = "<font color = red>"
        }
        else {
            $color = "<font color = black>"
        }
        if ($e -eq "True") {
            $body_e += "<td>" + $color + "&nbsp" + $temp1 + " <font size=3><b>MB</b></font></td>"
        }
        else {
            $body += "<td>" + $color + "&nbsp" + $temp1 + " <font size=3><b>MB</b></font></td>"
        }
           
    }

    if ($line -match "Bytes Rx") {
        $temp = ($line -split ":")
        $temp1 = ([math]::truncate(([int]::Parse($temp[2]) / 1Mb)))
        if ($temp1 -gt '1000') {
            $color = "<font color = red>"
        }
        else {
            $color = "<font color = black>"
        }
        if ($e -eq "True") {
            $body_e += "<td>" + $color + "&nbsp" + $temp1 + "<font size=3><b>MB</b></font></td>"
        }
        else {
            $body += "<td>" + $color + "&nbsp" + $temp1 + "<font size=3><b>MB</b></font></td>"
        }
    }


    if ($line -match "Duration ") {
        $line = ($line -split ":")
        if ($e -eq "True") {
            $body_e += "<td>" + "&nbsp" + $line[1] + ":" + $line[2] + "</td></tr>"
        }
        else {
            $body += "<td>" + "&nbsp" + $line[1] + ":" + $line[2] + "</td></tr>"
        }
       
    }
} 

$body += "</table></body>"
$body_e += "</table></body>"
$body | Foreach { $_ -replace "\@aura.dk", "" } | Foreach { $_ -replace "\@dinel.dk", "" } | Foreach { $_ -replace "AURA\\", "" } | Out-file $file
$body_e | Foreach { $_ -replace "\@aura.dk", "" } | Foreach { $_ -replace "\@dinel.dk", "" } | Foreach { $_ -replace "AURA\\", "" } | Out-file $file_e



#VPN DATA USAGE

$tidh = 0
$tidm = 0
$tids = 0
$tid = 0

$tx = 0
$rx= 0

$file = Get-Content $puttylog

foreach ($line in Get-Content $puttylog) {

    if ($line -match "Username     :") {
        $user = ($line.toupper() -split ':')[2]
        $containsWord = $file | %{$_ -match $user}
        $oldtx = 0
        $oldrx= 0
    if ($containsWord -contains $true) {

        $linenumber=Get-Content $puttylog_old | select-string $user -context 0,1
        #$linenumber.LineNumber
        if($linenumber.LineNumber -gt 0)
        {

        $temp = Get-Content $puttylog_old | Select -Index ($linenumber.LineNumber[0]+1)
        $temp = ($temp -split ":")
        $temp2 = ($temp[1] -replace "[^0-9]" , '')
        
        $oldtx = $temp2
        $temp2 = ($temp[2] -replace "[^0-9]" , '')
        
        $oldrx = $temp2
    }
                }
    }   

    if ($line -match "Bytes Tx") {
      
        $temp = ($line -split ":")
        $temp2 = ($temp[1] -replace "[^0-9]" , '')
        
        $temp2 = $temp2 - $oldtx
        if($temp2 -gt 0)
        {
        $tx = $tx + $temp2
        }
    }

    if ($line -match "Bytes Rx") {
        $temp = ($line -split ":")
        $temp2 = ($temp[2] -replace "[^0-9]" , '')
        
        $temp2 = $temp2 - $oldrx
        
        if($temp2 -gt 0)
        {       
             $rx = $rx + $temp2
        }
    }


    if ($line -match "Duration ") {
        $line = ($line -split ":")
 $tidh = $tidh +  $line[1].trimend("h").trimstart(" ")
$tidm = $tidm + $line[2].trimend("m")
$tids = $tids + $line[3].trimend("s")    
    }
} 
$tid = $tidh*3600
$tid = $tid + $tidm*60
$tid = $tid + $tids
#$tid

$tx
$rx

$temp = "<html><body>Description: Anyconnect Usage.`n[" + ($tx) +  "][" + ($rx ) +"]`n</body></html>"

write $temp |out-file -filepath \\mgmt01\PRTG\vpnusage.html -Encoding UTF8

get-content "$puttylog_old" | set-content "c:\scripts\putty.log-temp_old_old"

get-content $puttylog | set-content "$puttylog_old"


