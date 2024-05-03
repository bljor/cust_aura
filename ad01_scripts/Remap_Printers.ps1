#Server name definition 

$OldServerName1 = "printserver01" 

$NewServerName1 = "UNIFLOW" 

  

  

$DestinationPath = "c:\Temp\" 

$FileName = "$ENV:ComputerName - $ENV:UserName.txt" 

  

  

#Get existing network printers 

$CurrentPrinters = Get-WmiObject Win32_Printer | 

Where-Object {($_.Network -eq "true") -and ($_.SystemName -eq "\\"+$OldServerName1)} 

  

#Get default printer 

$Defaultprinter = Get-WmiObject -Query " SELECT * FROM Win32_Printer WHERE Default=$true" | Select-Object -ExpandProperty ShareName 

  

#Map the printers from a new server. 

if ($CurrentPrinters | Select-Object -ExpandProperty Name | ForEach-Object { 

$newprintername = $_ -Replace( "$OldServerName1", "$NewServerName1" ) 

Add-Printer -ConnectionName $newprintername 

  

}){} 

#Delete old printers 

$CurrentPrinters | foreach{$_.delete()} 

  

#Set default printer 

(Get-WMIObject -ClassName win32_printer |Where-Object -Property ShareName -eq $Defaultprinter).SetDefaultPrinter() 

  

#Get existing network printers for file output 

  

$CurrentPrintersfileoutput = Get-WmiObject Win32_Printer | Where-Object {($_.Network -eq "true") -and ($_.SystemName -eq "\\"+$OldServerName1)} 

  

#write file 

  

if ($CurrentPrintersfileoutput.Systemname -match $OldServer) 

{ 

    New-Item -Path $DestinationPath -Name $FileName -Force 

    Add-Content -Path "$DestinationPath\$FileName" -Value $CurrentPrinters 

} 