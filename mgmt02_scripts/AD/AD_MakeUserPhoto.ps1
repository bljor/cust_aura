



# ---------------- #


function Shrink-Image {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true, Position=0)]
        [Alias("FileName")]
        [ValidateScript({Test-Path $_ -PathType Leaf})]
        [string]$ImagePath, 

        [int]$TargetSize,

        [int]$Quality = 90,

        [string]$ImgName,

        [string]$ImgPath
    )

    Add-Type -AssemblyName "System.Drawing"

    $img = [System.Drawing.Image]::FromFile($ImagePath)

    # set the encoder quality
    $ImageEncoder = [System.Drawing.Imaging.Encoder]::Quality
    $encoderParams = New-Object System.Drawing.Imaging.EncoderParameters(1)
    $encoderParams.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter($ImageEncoder, $Quality)

    # set the output codec to jpg
    $Codec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() | Where-Object {$_.MimeType -eq 'image/jpeg'}

    # calculate the image ratio
    $ratioX = [double]($TargetSize / $img.Width)
    $ratioY = [double]($TargetSize / $img.Height)
    if ($ratioX -le $ratioY) { $ratio = $ratioX } else { $ratio = $ratioY }

    $newWidth  = [int]($img.Width * $ratio)
    $newHeight = [int]($img.Height * $ratio)
    $newImage  = New-Object System.Drawing.Bitmap($newWidth, $newHeight)

    $graph = [System.Drawing.Graphics]::FromImage($newImage)
    $graph.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic

    $graph.Clear([System.Drawing.Color]::White)
    $graph.DrawImage($img, 0, 0, $newWidth, $newHeight)

    # save the new image
    $OutputPath =$ImgPath+$ImgName+'.jpg' 
    #$OutputPath =$ImgPath+$ImgName+'-'+$TargetSize+'.jpg'

    # For safety: a [System.Drawing.Bitmap] does not have a "overwrite if exists" option for the Save() method
    if (Test-Path $OutputPath) { Remove-Item $OutputPath -Force }
    $newImage.Save($OutputPath, $Codec, $($encoderParams))

    $graph.Dispose()
    $newImage.Dispose()
    $img.Dispose()

    return $OutputPath
}



# ---------------- #

function Make-ADUserPicture {
    [CmdletBinding(DefaultParameterSetName = 'ByName')]
    param (
        [String]$Identity,
        [String]$ImageFile,
        [String]$OutputPath

    )

    try {
        # create a thumbnail using the original image, and size it down to 96x96 pixels
        $pictureFile = Shrink-Image -ImagePath $ImageFile -TargetSize 96 -ImgName $Identity.Split('-')[0] -ImgPath $OutputPath

        # create a thumbnail using the original image, and size it down to 300 pixels
        #$pictureFile = Shrink-Image -ImagePath $ImageFile -TargetSize 300 -ImgName $Identity.Split('-')[0] -ImgPath $OutputPath

        #Write $pictureFile
    }
    catch {
        Write-Error "Make-ADUserPicture: $($_.Exception.Message)"
    }

    finally {

    }
    
}


# ---------------- #

	



# ---------------- #
# Find alle billeder, recursivt fra placering
# for hvert fillede opret et tumpnail billede i output placeringen
# med Initialer som filnavn
# ---------------- #


$PhotoRoot ="\\aura\filer\HR\MedarbejderFoto\Færdig\"
$PhotoDest ="\\aura\filer\HR\MedarbejderFoto\Færdig_AD\"

#Tømmer mappe inden oprettelse af billeder
Remove-Item $PhotoDest"\*" -Force -Recurse


$fileNames = Get-ChildItem -Path $PhotoRoot -Recurse -Include *.jpg
ForEach($file in $fileNames)
{
    $SamAccountName = $file.basename.Split('-')[0] 
    $UserImagePath = $file.FullName
    Make-ADUserPicture -Identity $SamAccountName -ImageFile $UserImagePath -OutputPath $PhotoDest
    #write $SamAccountName
}
