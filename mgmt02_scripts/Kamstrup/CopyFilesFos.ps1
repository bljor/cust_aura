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

$destination = "\\aura.dk\DAX\DAXarkiv\DAXNET\DataUdveksling\FjernFos_Xellent\OMNIA SYSTEM\"
$session = New-Object WinSCP.Session

try
{
    # Connect
    $session.Open($sessionOptions)

    # Get list of file in the directory
    $directoryInfo = $session.ListDirectory("/Fos/")

    # Select the least recent file
        $latest =
            $directoryInfo.Files |
            Where-Object { -Not $_.IsDirectory } |
            Sort-Object LastWriteTime -Descending |
            Select-Object -Last 1

    # Only move if destination is empty
    if (-Not (Test-Path $destination -PathType leaf)) 
    {
        if ($latest) 
            { 
                # Transfer files
                $session.GetFiles(
                     ("/Fos/" + $latest), $destination, $True).Check()
            }
    }

    # Any file at all?
        if ($latest -eq $Null)
        {
            exit 1
        }
}


finally
{
    $session.Dispose()
}
