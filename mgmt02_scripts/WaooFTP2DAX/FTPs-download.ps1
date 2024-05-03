Start-Transcript -Path "C:\Scripts\WaooFTP2DAX\transscript.txt"
#Variabler
$ftpServer = "partnerftp.waoo.dk"
$ftpUser = "østjysk energi"
$ftpPass = "C:\Scripts\WaooFTP2DAX\$($env:USERNAME)-pwd.txt"
$limit = (Get-Date).AddDays(-10)
$tempFolder = "C:\Scripts\WaooFTP2DAX\FTPtemp\"

# Make pwd file
#"SomePassw0rd"  | ConvertTo-SecureString -AsPlainText -Force | ConvertFrom-SecureString | Out-File $ftpPass

# Fetch password
$Secure2 = Get-Content $ftpPass
$pass = $Secure2 | ConvertTo-SecureString
$Ptr = [System.Runtime.InteropServices.Marshal]::SecureStringToCoTaskMemUnicode($pass)
$decrypted = [System.Runtime.InteropServices.Marshal]::PtrToStringUni($Ptr)

# Load WinSCP .NET assembly
Add-Type -Path "C:\Scripts\WaooFTP2DAX\WinSCP-5.21.3-Automation\WinSCPnet.dll"


# Set up session options
$sessionOptions = New-Object WinSCP.SessionOptions -Property @{
    Protocol = [WinSCP.Protocol]::Ftp
    HostName = $ftpServer
    UserName = $ftpUser
    Password = $decrypted
    FtpSecure = [WinSCP.FtpSecure]::Explicit
    TlsHostCertificateFingerprint = "c0:96:60:b3:7d:c6:fc:65:0f:4d:2b:6f:62:2e:09:18:d3:45:c0:38:2d:c6:97:17:f1:f7:0d:e9:11:23:e1:72"
}

$session = New-Object WinSCP.Session

try
{
    # Connect
    $session.Open($sessionOptions)

    # Enumerate files to download
    $files = $session.EnumerateRemoteFiles("/MonthlyVODRCDR/", $Null, [WinSCP.EnumerationOptions]::AllDirectories) | Where-Object { $_.LastWriteTime -gt $limit }
    # Transfer files
    foreach($file in $files) { $session.GetFiles($file.FullName, $tempFolder).Check()}    
}
finally
{
    $session.Dispose()
}

#unzip
$zipFiles = get-item "$tempFolder\*.zip" | foreach {Expand-Archive -LiteralPath $_.FullName -DestinationPath $tempFolder }

#Move XML to destination
Move-Item -Path "$tempFolder\*CDR*.xml" -Destination \\db-ax\DaxArkiv\DAXProd\DataUdveksling\Waoo_Xellent_CDR\In\ -Force
Move-Item -Path "$tempFolder\*VODR*.xml" -Destination \\db-ax\DaxArkiv\DAXProd\DataUdveksling\Waoo_Xellent_VOD\In\ -Force

#cleanup
Remove-Item -Path $tempFolder\*.* -Force

Stop-Transcript