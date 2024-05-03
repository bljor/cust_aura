# Dette script sletter alle filer i den angivet sti som er ældre en 3 dage.


$path  = "\\SfB-Miralix01\L$\Wireshark_Trace"

Get-ChildItem -Path $path -Recurse -Force |
    Where-Object {($_.LastWriteTime -lt (Get-Date).AddDays(-3))} | 
    Remove-Item -Recurse -Force