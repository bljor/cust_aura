Get-ChildItem -Path "C:\Users\serviceuser\Prime" -Recurse | Where-Object {($_.LastWriteTime -lt (Get-Date).AddDays(-10))} | Remove-Item

Get-ChildItem -Path "C:\ISE" -Recurse | Where-Object {($_.LastWriteTime -lt (Get-Date).AddDays(-10))} | Remove-Item

