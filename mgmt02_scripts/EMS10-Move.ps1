#Flytter Filer, og omdåber til legacy
<#GE
$path = "\\aura.dk\dax\DAXarkiv\DAXNET\DataUdveksling\FjernFos_Xellent\EMS10_GALTEN"
$backuppath = "\\aura.dk\dax\DAXarkiv\DAXNET\DataUdveksling\FjernFos_Xellent\EMS10_ Galten_Backup"
$DestinationFile = "\\aura.dk\dax\DAXarkiv\DAXNET\DataUdveksling\FjernFos_Xellent\legacy"
$Item = Get-ChildItem -Path $path | Sort CreationTime | select -First 1  


if (-Not (Test-Path $DestinationFile -PathType leaf)) 
    {

        if ($Item) 
            { 
               Copy-Item ($path + "\" + $Item) $backuppath
               move-item ($path + "\" + $Item) $DestinationFile
            }
    }

#Flytter Filer, og omdåber til kam
#Odder --#>

$path = "\\aura.dk\DAX\DAXarkiv\DAXNET\DataUdveksling\FjernFos_Xellent\OMNIA SYSTEM"
$backuppath = "\\aura.dk\DAX\DAXarkiv\DAXNET\DataUdveksling\FjernFos_Xellent\OMNIA SYSTEM_backup"
$DestinationFile = "\\aura.dk\dax\DAXarkiv\DAXNET\DataUdveksling\FjernFos_Xellent\vision"
$Item = Get-ChildItem -Path $path | Sort CreationTime | select -First 1  


if (-Not (Test-Path $DestinationFile -PathType leaf)) 
    {

        if ($Item) 
            { 
               Copy-Item ($path + "\" + $Item) $backuppath
               move-item ($path + "\" + $Item) $DestinationFile
            }
    }