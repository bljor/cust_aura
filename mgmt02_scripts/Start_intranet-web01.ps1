[system.Diagnostics.Process]::Start("firefox","http://intranet-web01")
Start-Sleep -s 20
Get-Process firefox | Foreach-Object { $_.Kill() }