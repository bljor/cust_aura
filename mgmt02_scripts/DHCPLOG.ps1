 #DHCP01
 
  $Destination = "\\aura.dk\Services\Deployment\@log\DHCP"
 
 if(Test-Path -Path "\\dhcp01\c$\Windows\System32\dhcp\")
  {
    $logfiles = Get-ChildItem -File -Path "\\dhcp01\c$\Windows\System32\dhcp\" | Where-Object { $_.Extension -eq ".log" -and $_.Name.StartsWith("DhcpSrv") -and $_.LastAccessTime -lt (Get-Date).Date }
  }

 foreach($log in $logfiles)
  {
    $filedate = (Get-Date ($log.LastWriteTime) -format yyyy-MM-dd)
      Copy-Item ($log.DirectoryName + "\$log") ("$Destination\$filedate-" + "DHCP01-" + $log.Name)
      Write-Output "Copied $($log.DirectoryName)\$log to $Destination\$filedate-$($log.Name)"
  }
  

#DHCP02

 if(Test-Path -Path "\\dhcp02\c$\Windows\System32\dhcp\")
  {
    $logfiles = Get-ChildItem -File -Path "\\dhcp02\c$\Windows\System32\dhcp\" | Where-Object { $_.Extension -eq ".log" -and $_.Name.StartsWith("DhcpSrv") -and $_.LastAccessTime -lt (Get-Date).Date }
  }

 foreach($log in $logfiles)
  {
    $filedate = (Get-Date ($log.LastWriteTime) -format yyyy-MM-dd)
      Copy-Item ($log.DirectoryName + "\$log") ("$Destination\$filedate-" + "DHCP02-" + $log.Name)
      Write-Output "Copied $($log.DirectoryName)\$log to $Destination\$filedate-$($log.Name)"
  }