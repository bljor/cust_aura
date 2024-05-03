


Function CleanUpUser
{
    $dataSource="DB-SQL-2016-HOT.aura.dk"
    $database="ITstore"
    $query = “SELECT FolderName, INIT FROM IT_AdDisabledUsers_Sympa”


	$connectionString = “Server=$dataSource;Database=$database;Integrated Security=SSPI;”
	$connection = New-Object System.Data.SqlClient.SqlConnection
	$connection.ConnectionString = $connectionString
	$connection.Open()

	$command = $connection.CreateCommand()
	$command.CommandText = $query

	$result = $command.ExecuteReader()
    ForEach ($ITM in $result) 
    {
        $UserFolder = $ITM.GetValue(0)
        $path = "\\aura.dk\Filer\Brugere\$UserFolder"
        $User = $ITM.GetValue(1)

        Remove-UserFolder -RootFolder $path 
        Remove-UserPhotos -Identity $User

     }

    $connection.close()
}



function Remove-UserFolder {
    param (
        [String]$RootFolder
    )

    try {
		if (Test-Path $RootFolder){
          #Write-Host "MAPPE USERFOLDER $RootFolder" "Slettes..."
          Remove-Item -Path "$RootFolder" -filter *.* -recurse -Force
		}
    }
    catch {
        Write-Error "Remove-UserFolder: $($_.Exception.Message)"
    }

    finally {

    }
    
}


function Remove-UserPhotos {
    param (
        [String]$Identity
    )

    $RootFolder ="\\aura\filer\HR\MedarbejderFoto\"
    $UserName = $Identity

     try {
		if (Test-Path $RootFolder){
            #Write-Host "PHOTOS FOR $RootFolder $UserName*.* " "Slettes..."
            Get-ChildItem -Path $RootFolder -Recurse -Include $UserName*.* | Remove-Item #-Verbose
		}
    }

    catch {
        Write-Error "Remove-UserPhotos: $($_.Exception.Message)"
    }

    finally {
    }
    
}



CleanUpUser

