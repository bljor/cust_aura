# Load WinSCP .NET assembly
Add-Type -Path "C:\Program Files (x86)\WinSCP\WinSCPnet.dll"

# Fetch password
$Secure2 = Get-Content C:\scripts\Kamstrup\KamstrupFTP_Encrypted.txt
$pass = $Secure2 | ConvertTo-SecureString
$Ptr = [System.Runtime.InteropServices.Marshal]::SecureStringToCoTaskMemUnicode($pass)
$decrypted = [System.Runtime.InteropServices.Marshal]::PtrToStringUni($Ptr) 

# Set up session options
$sessionOptions = New-Object WinSCP.SessionOptions -Property @{
    Protocol = [WinSCP.Protocol]::Ftp
    HostName = "dlpfile.hstz3.amr.kamstrup.com"
    PortNumber = 990
    TlsHostCertificateFingerprint = "02:8d:66:ca:78:19:9e:6b:b2:a4:d3:25:2e:5f:35:a3:69:f8:4d:19"
    UserName = "DLPfile"
    Password = $decrypted
    FtpSecure = [WinSCP.FtpSecure]::Implicit
}

$session = New-Object WinSCP.Session

try
{
    # Connect
    $session.Open($sessionOptions)

    # Transfer files
    $session.GetFiles("/Dogn/*.*", "\\aura.dk\DAX\DAXarkiv\DAXNET\DataUdveksling\Aflaesninger\", $True).Check()
}
finally
{
    $session.Dispose()
}
