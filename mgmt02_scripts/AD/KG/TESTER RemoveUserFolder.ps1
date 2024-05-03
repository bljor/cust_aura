


Function CleanUpFolders
{
    $dataSource="DB-SQL-2016-HOT.aura.dk"
    $database="ITstore"
    $query = “SELECT FolderName FROM IT_AdDisabledUsers_Test”


	$connectionString = “Server=$dataSource;Database=$database;Integrated Security=SSPI;”
	$connection = New-Object System.Data.SqlClient.SqlConnection
	$connection.ConnectionString = $connectionString
	$connection.Open()

	$command = $connection.CreateCommand()
	$command.CommandText = $query

	$result = $command.ExecuteReader()
    ForEach ($ITM in $result) 
    {

        $User = $ITM.GetValue(0)

        $path = "\\aura.dk\Filer\Brugere\@TEST\$User"

		if (Test-Path $path)
		{
          Write-Host "MAPPE $path" "Slettes..."
           Remove-Item -Path "$path" -filter *.* -recurse -Force
		}
     }

    $connection.close()
}

CleanUpFolders


