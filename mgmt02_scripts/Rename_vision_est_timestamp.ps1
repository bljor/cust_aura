$FileName = "\\aura.dk\DAX\DAXarkiv\DAXNET\DataUdveksling\FjernFos_Xellent\ESTIMERING\NSM\ESTIMERING\vision_est"

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

# Display the new name
#"New filename: $nameOnly-$DateStamp$extOnly"