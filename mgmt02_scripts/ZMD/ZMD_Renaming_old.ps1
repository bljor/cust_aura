# Modified version dato: 23/11-2021

#Step1: Kopier filer i $FOS_Source_path & $Resend_Source_Path til $Backup_path
#Step2: Filer flyttes fra $FOS_Source_path en efter en (hvert minut kommer DAX forbi og "spiser" de filer som ligger tilgængelig, der kan kun ligge en fil af gangen) til $ZMD_Destination 
$log                     = "C:\Scripts\ZMD\log-$(Get-Date -Format "yyy-MM-dd").log"
$FOS_Source_path         = "\\sftp01\c$\Share\landisgyr\FOS"
$FOS_Source_files        = Get-ChildItem $FOS_Source_path | Select-Object Name, FullName, Extension
$ZMD_Destination         = "\\aura.dk\DAX\DAXarkiv\DAXNET\DataUdveksling\FjernFos_Xellent"
$Resend_Source_Path      = "\\sftp01\c$\Share\landisgyr\Resend"
$Resend_Source_files     = Get-ChildItem -Path $Resend_Source_Path | Select-Object Name, FullName, Extension
$ZMD_Monthly_source      = "\\sftp01\c$\Share\landisgyr\Monthly"
$ZMD_Monthly_files       = Get-ChildItem $ZMD_Monthly_source | Select-Object Name, FullName, Extension
$ZMD_Monthly_Destination = "\\aura.dk\DAX\DAXarkiv\DAXNET\DataUdveksling\Aflaesninger\AIM"

function Get-TimeStamp
{
    $format = "[yyy/MM/dd HH:mm:ss:fff]:"
    Return $(Get-Date -Format $format)
}

foreach ($file in $FOS_Source_files)
{
    Try 
    {
	    Copy-Item $($file.FullName) -Destination "\\aura.dk\DAX\DAXarkiv\DAXNET\DataUdveksling\FjernFos_Xellent\ESTIMERING\Backup\$($file.Basename).fos"
        # Renamer filer udfra index 4 (ZMD_2_abc) = 2 index starter ved 0
        if (!(Test-Path "$ZMD_Destination\ZMD_$($file.Name[4])"))
        {
            Move-Item $($file.FullName) -Destination "$ZMD_Destination\ZMD_$($file.Name[4]).fos"
            #Move-Item $($file.FullName) -Destination "$ZMD_Destination\ZMD_$($file.Name[4])"
            Add-Content -Value "$(Get-TimeStamp) - Success - Move-Item $($file.FullName) -Destination ""$ZMD_Destination\ZMD_$($file.Name[4])""" -Path $log
        }
        else
        {
            Add-Content -Value "$(Get-TimeStamp) - Error - file: $($file.FullName) already exists in folder: $ZMD_Destination" -Path $log
        }
	}
    catch
    { 
        Write-Error $_
        Add-Content -Value "$(Get-TimeStamp) $_" -Path $log
    }
}

#Step3: Filer flyttes fra $Resend_Source_Path en efter en (hvert minut kommer DAX forbi og "spiser" de filer som ligger tilgængelig, der kan kun ligge en fil af gangen) til $ZMD_Destination
# Scriptet skal kører hvert minut eller hvert 5. minut

foreach ($file in $Resend_Source_files)
{
    Try 
    {
        Copy-Item $($file.FullName) -Destination "\\aura.dk\DAX\DAXarkiv\DAXNET\DataUdveksling\FjernFos_Xellent\ESTIMERING\Backup\$($file.Basename).fos"

        if (!(Test-Path "$ZMD_Destination\ZMD_$($file.Name[11])"))
        {
            Move-Item $($file.FullName) -Destination "$ZMD_Destination\ZMD_$($file.Name[11]).fos"
            #Move-Item $($file.FullName) -Destination "$ZMD_Destination\ZMD_$($file.Name[11])"
            Add-Content -Value "$(Get-TimeStamp) - Success - Move-Item $($file.FullName) -Destination ""$ZMD_Destination\ZMD_$($file.Name[11])""" -Path $log
        }
        else
        {
            Add-Content -Value "$(Get-TimeStamp) - error - file: $($file.FullName) already exists in folder: $ZMD_Destination" -Path $log
        }
    } 
    Catch
    { 
        Write-Error $_
        Add-Content -Value "$(Get-TimeStamp) $_" -Path $log
    }
}

#Step4: Filer i $ZMD_Monthly_Source flyttes til $ZMD_Monthly_Destination ->> der skal ikke gøres yderligere.

foreach ($file in $ZMD_Monthly_files)
{
    try
    {
        Move-Item $($file.FullName) -Destination "$($ZMD_Monthly_Destination).fos"
	    #Move-Item $($file.FullName) -Destination $ZMD_Monthly_Destination
        Add-Content -Value "$(Get-TimeStamp) Move-Item $($file.FullName) -Destination $ZMD_Monthly_Destination" -Path $log
    }
    catch 
    {
        Add-Content -Value "$(Get-TimeStamp) $_" -Path $log
    }
}