

Function CreateUserFolders
{
    $dataSource="DB-SQL-2016-HOT.aura.dk"
    $database="ITstore"
    $query = “SELECT * FROM IT_AdCreateUserFolder_Test”
    #$query = “SELECT * FROM IT_AdCreateUserFolder”


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
        $Sam = $ITM.Getvalue(1)
        $path = "\\aura.dk\Filer\Brugere\@TEST\$User"
      
        #$User = "ANDAND - Anders And"
        #$Sam = "ANDAND"
        #$path = "\\aura.dk\Filer\Brugere\@TEST\$User"
       
        #Tjek om user findes i AD, Hvis ikke skal mappen ikke oprettes..."
        $UserTest = Get-ADUser -LDAPFilter "(sAMAccountName=$Sam)"
        
        If ( -not ($UserTest -eq $Null)) {

		    if ( -not (Test-Path $path) ) { 

                New-Item -ItemType Directory -Path $path

                $Acl = Get-Acl $path
		
                $Ar = New-Object System.Security.AccessControl.FileSystemAccessRule($Sam, "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
		        $Acl.SetAccessRule($Ar)
        
                $Acl.SetAccessRuleProtection($True, $True)
                Set-Acl $path $Acl 
                #Write-Host "refresh object samUser:$Sam"

                # refresh object
                $Acl = Get-Acl $path
                $accessrule = New-Object system.security.AccessControl.FileSystemAccessRule("NT AUTHORITY\Authenticated Users","Read",,,"Allow")
		        $acl.RemoveAccessRuleAll($accessrule)
	            Set-Acl $path $Acl 

            }
        }

        # skal udkommenteres i prod
        ELSE {
            Write-Host "Bruger findes ikke i AD samUser:$Sam"
        }

     }

    $connection.close()
}


CreateUserFolders