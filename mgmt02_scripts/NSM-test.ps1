#Omdøber og flytter Filer

$path = "\\aura.dk\DAX\DAXarkiv\DAXNET\DataUdveksling\FjernFos_Xellent\ESTIMERING\NSM\"
$FileExists = Test-Path "\\aura.dk\DAX\DAXArkiv\DAXNET\DataUdveksling\FjernFos_Xellent\vision_est"
$fileName = Get-ChildItem -File "$Path"
$TimeStamp = "\\aura.dk\DAX\DAXArkiv\DAXNET\DataUdveksling\FjernFos_Xellent\ESTIMERING\NSM\Backup\"



if ($FileExists -ne $True) 
    
{

foreach ($file in $fileName) 
	    {
               
		$filestring = $path + $file
        $Filestring2 = $TimeStamp + $file
        Copy-Item $Filestring -Destination "\\aura.dk\DAX\DAXarkiv\DAXNET\DataUdveksling\FjernFos_Xellent\ESTIMERING\NSM\Backup" #Lægger original fil med navn op i backup. Ønskes omdøbt fil før kopiering, flyt denne linje til bunden. Se udkommenteret linje
					           
		   $fileObj = get-item $filestring
           $nameOnly = $fileObj.BaseName
           
           $newfile = "$nameOnly" 
                 
           $newfile = $newfile -replace 'vision_.*','vision_est'
           rename-item "$fileObj" "$newfile"
           $DateStamp = Get-Item $Filestring2 | Foreach {$_.LastWriteTime.tostring("dd-MM-yyyy@HH-mm-ss")}
           $Filestring = $path + $newfile
           #Copy-Item $Filestring -Destination "\\aura.dk\DAX\DAXarkiv\DAXNET\DataUdveksling\FjernFos_Xellent\ESTIMERING\NSM\Backup" 
           Move-Item $filestring -Destination "\\aura.dk\DAX\DAXarkiv\DAXNET\DataUdveksling\FjernFos_Xellent\ESTIMERING\NSM\ESTIMERING\"
                            
 }



}
exit