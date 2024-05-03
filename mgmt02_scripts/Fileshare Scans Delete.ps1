$limit = (Get-Date).AddDays(-14)

$path = "\\aura.dk\Filer\Common\PrintScan"
Get-ChildItem -Path $path -file -Recurse | where { $_.LastWriteTime -lt $limit} | Remove-Item

$path2 = "\\fil-print\common\Scannere"
Get-ChildItem -Path $path2 -file -Recurse | where { $_.LastWriteTime -lt $limit} | Remove-Item