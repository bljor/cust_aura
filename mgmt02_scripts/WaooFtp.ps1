#Henter filer fra Waoo FTP

$File = "\\aura.dk\Services\DataExchange\WaooFtp\Alle_Produkter_Alle_Partnere.csv"
$ftp = "ftp://østjysk energi:Mx4ELQOOOA@partnerftp.waoo.dk/Data/Alle_Produkter_Alle_Partnere.csv"

$webclient = New-Object System.Net.WebClient
$uri = New-Object System.Uri($ftp)

$webclient.DownloadFile($uri, $File)

