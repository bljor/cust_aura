

function Check-ADUserPicture {
    param (
        [String]$Identity
    )
    
    $User = Get-ADUser -Identity $Identity -properties thumbnailPhoto
        try {
            $Img = $User.thumbnailPhoto.length
        }
        catch {
            $Img=1
        }

      return $Img
 }



 function Add-ADUserPicture {
    param (
        [String]$Identity,
        [String]$ImageFile
    )
        
        $User = Get-ADUser -Identity $Identity

        try {
            [byte[]]$pictureData = [System.IO.File]::ReadAllBytes($ImageFile)
            $User | Set-ADUser -Replace @{thumbnailPhoto = $pictureData } -ErrorAction Stop
            }

        catch {  
            Write-Error "Add-ADUserPicture: $($_.Exception.Message)"
         }

    }





$PhotoRoot ="\\aura\filer\HR\MedarbejderFoto\Færdig_AD\"
$fileNames = Get-ChildItem -Path $PhotoRoot -Recurse -Include *.jpg

ForEach($file in $fileNames){
    $SamAccountName = $file.basename 
    $result =  Check-ADUserPicture -Identity $SamAccountName
    #write "Result:$SamAccountName' - '$result"

    if ($result -eq 0){
      Add-ADUserPicture -Identity $SamAccountName -ImageFile $file
      #write  $SamAccountName ' - ' $file
    }
       
}

