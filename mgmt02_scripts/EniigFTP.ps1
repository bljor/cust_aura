# Load WinSCP .NET assembly
Add-Type -Path "C:\Program Files (x86)\WinSCP\WinSCPnet.dll"

# Fetch password
$Secure2 = Get-Content C:\scripts\Eniig_Norlys_SecureString.txt
$pass = $Secure2 | ConvertTo-SecureString
$Ptr = [System.Runtime.InteropServices.Marshal]::SecureStringToCoTaskMemUnicode($pass)
$decrypted = [System.Runtime.InteropServices.Marshal]::PtrToStringUni($Ptr) 


# Set up session options
$sessionOptions = New-Object WinSCP.SessionOptions -Property @{
    Protocol = [WinSCP.Protocol]::Sftp
    HostName = "217.198.222.147"
    UserName = "aura"
    Password = $decrypted
    SshHostKeyFingerprint = "ssh-rsa 2048 jmpYSm04WhqHI8t4TCKA+J414s+ClWQIvZlk4Aflw6M="
}

$session = New-Object WinSCP.Session

try
{
    # Connect
    $session.Open($sessionOptions)

    # Transfer files
    $session.GetFiles("/SI_Revision/*.*", "\\aura.dk\Services\DataExchange\EniigFtp\").Check()
}
finally
{
    $session.Dispose()
}