Get-ChildItem -Path "C:\inetpub\logs\LogFiles\W3SVC1" -Recurse | Where-Object {($_.LastWriteTime -lt (Get-Date).AddDays(-60))} | Remove-Item

Get-ChildItem -Path "C:\inetpub\logs\LogFiles\W3SVC2" -Recurse | Where-Object {($_.LastWriteTime -lt (Get-Date).AddDays(-60))} | Remove-Item

Get-ChildItem -Path "C:\inetpub\logs\LogFiles\W3SVC3" -Recurse | Where-Object {($_.LastWriteTime -lt (Get-Date).AddDays(-60))} | Remove-Item

Get-ChildItem -Path "C:\inetpub\logs\LogFiles\W3SVC4" -Recurse | Where-Object {($_.LastWriteTime -lt (Get-Date).AddDays(-60))} | Remove-Item

