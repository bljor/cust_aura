# Dette script sletter alle filer i den angivet sti som er ældre en 10 dage.


$path  = "\\Invoices\C$\Users\Public\READSOFT\INVOICES\Log\CrashRpt\INVOICES Transfer 5-9 SP1 SP 1build 18031"

Get-ChildItem -Path $path -Recurse -Force |
    Where-Object {($_.LastWriteTime -lt (Get-Date).AddDays(-3))} | 
    Remove-Item -Recurse -Force