# Dette script sletter alle filer i den angivet sti som er ældre en 30 dage.


$path  = "\\aura.dk\Services\DataExchange\Log\Passwordexpire"

Get-ChildItem -Path $path -Recurse -Force |
    Where-Object {($_.LastWriteTime -lt (Get-Date).AddDays(-30))} | 
    Remove-Item -Recurse -Force