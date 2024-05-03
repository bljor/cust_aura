#Omddøber filer med data og tid 
$fileName = @("legacy","kam","vision","enermet.fos","ZMD_1.fos","ZMD_2.fos","ZMD_3.fos","ZMD_4.fos","Viby_EMH.fos","*$")
$path = "\\aura.dk\DAX\DAXarkiv\DAXNET\DataUdveksling\FjernFos_Xellent\Backup\"
$timeout = new-timespan -Seconds 50
$sw = [diagnostics.stopwatch]::StartNew()
$debug = 1

while ($sw.elapsed -lt $timeout)
{
     foreach ($file in $fileName) 
	    {


            
            if($debug -eq 1) { write-host "0" +  $nameOnly }
		    $filestring = $path + $file
			    if (Test-Path $filestring)
			    {
                    if($debug -eq 1) { write-host "1" + $file }
				        $fileObj = get-item $filestring
                        $nameOnly = $fileObj.BaseName
				        $DateStamp = Get-Item $filestring | Foreach {$_.LastWriteTime.tostring("dd-MM-yyyy@HH-mm-ss")}
				        $extOnly = $fileObj.extension
			    if ($extOnly.length -eq 0)
				    {
					    $nameOnly = $fileObj.Name
                        $newfile = "$nameOnly-$DateStamp"
                        $newfile = $newfile -replace '[$]',''
                    
                        if (Test-Path ($path + $newfile))
                            {
                             $random = Get-Random -Maximum 1000 -Minimum 1 
                             
                             $path + $newfile
                             $newfile = "$nameOnly-$DateStamp" + "$random"
                             $newfile = $newfile -replace '[$]',''
                            }
					    rename-item "$fileObj" "$newfile"

			       }
			    else 
				    {
                    $sti = $path+$nameOnly +"-" +$DateStamp+$extOnly
                        if($debug -eq 1) { write-host "3" $sti }
                        if($debug -eq 1) { write-host "4" $path$nameOnly"-"$DateStamp$extOnly }
                        if (Test-Path ($sti))
                            {
                                $random = Get-Random -Maximum 1000 -Minimum 1
                                
                                $path + $newfile
                                $newfile = "$nameOnly-$DateStamp" + "$random" + $extOnly
                                $newfile = $newfile -replace '[$]',''
                                rename-item "$filestring" "$newfile"
                            }
        
                        else 
				            {
					            $nameOnly = $fileObj.Name.Replace( $fileObj.Extension,'')
					            rename-item "$filestring" "$nameOnly-$DateStamp$extOnly"
                            }
				    }
			    }

	    }
    start-sleep -seconds 5
}

exit