
function zipfiles ()
{
    cd C:\Temp\LOGS\
    dir *.log | ForEach-Object { & "C:\Program Files\7-Zip\7z.exe" a -tzip ($_.Name+".zip") $_.Name }
}

function delfiles ()
{
    cd C:\Temp\LOGS\
    dir *.log| ForEach-Object { Remove-Item -Force $_.FullName } 
}

function delolds ()
{
    $old = 30
    $now = Get-Date
    $path = 'C:\Temp\LOGS\'

    Get-ChildItem $path -Recurse |
    Where-Object {-not $_.PSIsContainer -and $now.Subtract($_.CreationTime).Days -gt $old } |
    Remove-Item -WhatIf
}

function del30days ()
{
    Get-ChildItem -Path "C:\Temp\LOGS\" -Recurse -File 
    Where CreationTime -lt  (Get-Date).AddDays(-30)
    Remove-Item -Force
}

zipfiles
delfiles
delolds
del30days