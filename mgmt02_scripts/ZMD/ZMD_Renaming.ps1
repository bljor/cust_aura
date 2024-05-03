# Modified version dato: 02-12-2021

# log properties
$log                     = "C:\Scripts\ZMD\log-$(Get-Date -Format "yyy-MM-dd").log"
#

#Step1: Kopier filer i $FOS_Source_path & $Resend_Source_Path til $Backup_path
#Step2: Filer flyttes fra $FOS_Source_path en efter en (hvert minut kommer DAX forbi og "spiser" de filer som ligger tilgængelig, der kan kun ligge en fil af gangen) til $ZMD_Destination 

# Flyt filer fra FOS_Source_Files og Resend_Source_Files til $ZMD_Destination
$FOS_Source_path         = "\\sftp01\c$\Share\landisgyr\FOS"
$FOS_Source_files        = Get-ChildItem $FOS_Source_path | Select-Object Name, FullName
$Resend_Source_Path      = "\\sftp01\c$\Share\landisgyr\Resend"
$Resend_Source_files     = Get-ChildItem -Path $Resend_Source_Path | Select-Object Name, FullName
$Fos_files               = $FOS_Source_files + $Resend_Source_files
$ZMD_Destination         = "\\aura.dk\DAX\DAXarkiv\DAXNET\DataUdveksling\FjernFos_Xellent\ZMD"
#

# Flyt filer fra $ZMD_Monthly_Files til -> $ZMD_Monthly_Destionation
$ZMD_Monthly_source      = "\\sftp01\c$\Share\landisgyr\Monthly"
$ZMD_Monthly_files       = Get-ChildItem $ZMD_Monthly_source | Select-Object Name, FullName
$ZMD_Monthly_Destination = "\\aura.dk\DAX\DAXarkiv\DAXNET\DataUdveksling\Aflaesninger\AIM"
#

# Flytning af filer fra $ZMD_Destionation til $ZMD_backup + $FjernFos_Xellent
$ZMD_Backup              = "\\aura.dk\DAX\DAXarkiv\DAXNET\DataUdveksling\FjernFos_Xellent\ZMD backup"
$FjernFos_Xellent        = "\\aura.dk\DAX\DAXarkiv\DAXNET\DataUdveksling\FjernFos_Xellent"
#

function Get-TimeStamp
{
    $format = "[yyy/MM/dd HH:mm:ss:fff]:"
    Return $(Get-Date -Format $format)
}

foreach ($file in $Fos_files)
{
    Try 
    {
        if (!(Test-Path "$ZMD_Destination\$($file.Name)"))
        {
            Move-Item $($file.FullName) -Destination "$ZMD_Destination\$($file.Name)"
            Add-Content -Value "$(Get-TimeStamp) - Success - Move-Item $($file.FullName) -Destination ""$ZMD_Destination\$($file.Name)""" -Path $log
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

#Step4: Filer i $ZMD_Monthly_Source flyttes til $ZMD_Monthly_Destination ->> der skal ikke gøres yderligere.

foreach ($file in $ZMD_Monthly_files)
{
    try
    {
        Move-Item $($file.FullName) -Destination "$($ZMD_Monthly_Destination)\$($file.Name)"
        Add-Content -Value "$(Get-TimeStamp) Move-Item $($file.FullName) -Destination $($ZMD_Monthly_Destination)\$($file.Name)" -Path $log
    }
    catch 
    {
        Add-Content -Value "$(Get-TimeStamp) $_" -Path $log
    }
}

$ZMD_DestinationFiles = Get-ChildItem $ZMD_Destination -File| Select-Object Name, FullName

foreach ($file in $ZMD_DestinationFiles)
{
    try 
    {
        $XellentDestination = "$($FjernFos_Xellent)\$(($file.Name -replace 'Resend_').SubString(0,5)).fos"
        $destionation = "$ZMD_Backup\$($file.Name)"

        Copy-Item -Path $($file.FullName) -Destination $destionation
        Add-Content -Value "$(Get-TimeStamp) Copy-Item $($file.FullName) -Destination $destionation" -Path $log

        if (Test-Path $destionation)
        {
            if (!(Test-Path $XellentDestination))
            {
                Move-Item -Path $File.FullName -Destination "$XellentDestination"  
                Add-Content -Value "$(Get-TimeStamp) Move-Item -Path $($File.FullName) -Destination $XellentDestination" -Path $log
            }
            else
            {
                Add-Content -Value "$(Get-TimeStamp) Error - file already exists on destination: $XellentDestination" -Path $log
            }
        }
        else
        {
            Add-Content -Value "$(Get-TimeStamp) Error - File: $($file.FullName) does not exist in backup folder: $Destionation. Skipping moving file to: $XellentDestination" -Path $log
        }
    }
    catch
    {
        Add-Content -Value "$(Get-TimeStamp) $_" -Path $log
    }
}