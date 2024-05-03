#Omdøber og flytter Filer

$path = "\\aura.dk\DAX\DAXarkiv\DAXNET\DataUdveksling\FjernFos_Xellent\ESTIMERING\"
$FileExists = Test-Path "\\aura.dk\DAX\DAXArkiv\DAXNET\DataUdveksling\FjernFos_Xellent\vision_est"
$fileName = Get-ChildItem -File "$Path"



if ($FileExists -ne $True) 
    
{

foreach ($file in $fileName) 
	    {
               
		$filestring = $path + $file
        Copy-Item $Filestring -Destination "\\aura.dk\DAX\DAXarkiv\DAXNET\DataUdveksling\FjernFos_Xellent\ESTIMERING\Backup" #Lægger original fil med navn op i backup. Ønskes omdøbt fil før kopiering, flyt denne linje til bunden. Se udkommenteret linje
					           
		   $fileObj = get-item $filestring
           $nameOnly = $fileObj.BaseName
		   $newfile = "$nameOnly" 
                 
           $newfile = $newfile -replace 'vision_.*','vision_est'
		   rename-item "$fileObj" "$newfile"
           $Filestring = $path + $newfile
           #Copy-Item $Filestring -Destination "\\aura.dk\DAX\DAXarkiv\DAXNET\DataUdveksling\FjernFos_Xellent\ESTIMERING\NSM\Backup" 
           Move-Item $filestring -Destination "\\aura.dk\DAX\DAXarkiv\DAXNET\DataUdveksling\FjernFos_Xellent\"
                            
 }




}

$FileName = "\\aura.dk\DAX\DAXarkiv\DAXNET\DataUdveksling\FjernFos_Xellent\Backup\vision_est"

# Check the file exists
if (-not(Test-Path $fileName)) {break}

$fileObj = get-item $fileName
$DateStamp = get-date -uformat "%d-%m-%y@%H-%M-%S"

$extOnly = $fileObj.extension

if ($extOnly.length -eq 0) {
   $nameOnly = $fileObj.Name
   rename-item "$fileObj" "$nameOnly-$DateStamp"
   }
else {
   $nameOnly = $fileObj.Name.Replace( $fileObj.Extension,'')
   rename-item "$fileName" "$nameOnly-$DateStamp$extOnly"
   }
exit