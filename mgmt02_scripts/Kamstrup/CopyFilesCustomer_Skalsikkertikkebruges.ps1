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
    TlsHostCertificateFingerprint = "‎‎4c:56:3f:cc:dd:6e:9c:c8:8a:37:07:74:4d:3d:9e:ce:45:85:8f:5a"
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
    $session.GetFiles("/Customer/*.*", "\\aura.dk\DAX\DAXarkiv\DAXNET\DataUdveksling\VA eksport\", $True).Check()
}
finally
{
    $session.Dispose()
}
