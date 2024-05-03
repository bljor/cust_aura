#Omdøber og flytter Filer

$path = "\\sftp01\c$\Share\landisgyr\test\FOS\"
$FileExists = Test-Path "\\sftp01\c$\Share\landisgyr\test\ZMD_*"
$fileName = Get-ChildItem -File $Path



if ($FileExists -ne $True) 
    
{

foreach ($file in $fileName) 
	    {
               
		$formatFileName = ($file.Name).Split("_")
        $newFileName = $formatFileName[0] + "_" + $formatFileName[1]
        $Filestring = $path + $file
        Rename-Item -Path $Filestring -NewName $newFileName 
        #Copy-Item $Filestring -Destination "\\aura.dk\DAX\DAXarkiv\DAXNET\DataUdveksling\FjernFos_Xellent\ESTIMERING\NSM\Backup" 
        Move-Item -Path "\\sftp01\c$\Share\landisgyr\test\FOS\ZMD_1" -Destination "\\sftp01\c$\Share\landisgyr\test"
        Move-Item -Path "\\sftp01\c$\Share\landisgyr\test\FOS\ZMD_2" -Destination "\\sftp01\c$\Share\landisgyr\test"
        Move-Item -Path "\\sftp01\c$\Share\landisgyr\test\FOS\ZMD_3" -Destination "\\sftp01\c$\Share\landisgyr\test"
        Move-Item -Path "\\sftp01\c$\Share\landisgyr\test\FOS\ZMD_4" -Destination "\\sftp01\c$\Share\landisgyr\test"
                            
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