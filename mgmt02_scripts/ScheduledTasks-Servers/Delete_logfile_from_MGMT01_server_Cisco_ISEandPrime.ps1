# Dette script sletter alle filer i den angivet sti som er ældre en 10 dage.
# Benyttes i forbindelse med oprydning af Cisco ISE og Prime filer


$pathPrime  = "\\MGMT01\C$\Users\serviceuser\Prime"

Get-ChildItem -Path $pathPrime -Recurse -Force |
    Where-Object {($_.LastWriteTime -lt (Get-Date).AddDays(-10))} | 
    Remove-Item -Recurse -Force


$pathISE  = "\\MGMT01\C$\ISE"

Get-ChildItem -Path $pathISE -Recurse -Force |
    Where-Object {($_.LastWriteTime -lt (Get-Date).AddDays(-10))} | 
    Remove-Item -Recurse -Force