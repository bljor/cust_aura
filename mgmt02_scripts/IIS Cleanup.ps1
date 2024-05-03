$servers = "sccm01","mail01","mail02","intranet-web01","ad01","ad02","dinel-web"
foreach($s in $servers)
{
$FileExists = Test-Path \\$s\c$\inetpub\logs\LogFiles
    If ($FileExists -eq $True) 
        {
            Get-ChildItem –Path "\\$s\c$\inetpub\logs\LogFiles\W3SVC*\*.log" -Recurse | Where-Object {($_.LastWriteTime -lt (Get-Date).AddDays(-60))} | Remove-Item
        }
}