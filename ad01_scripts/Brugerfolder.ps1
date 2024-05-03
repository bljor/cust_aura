
# 04-06-18 KG, ændret så ALLE aura brugere for oprettet en fortrolig mappe
#kg ændret -searchbase til kun at kigge i OU 'AURA' under 'AURA users' (udelukker at eksterne og service acconts får oprettet mappe)

$ADUsers = Get-ADUser -server ad01.aura.dk	 -Filter * -searchbase "OU=AURA,OU=AURA Users,DC=aura,DC=dk" -Properties *

ForEach ($ADUser in $ADUsers) 
{
if ($ADUser.memberof -like "CN=grp.*")
	{
		$path = "\\filprint.aura.dk\E$\Filer\Brugere\$($ADUser.sAMAccountname.ToUpper()) - $($ADUser.DisplayName)"

		if ( -not (Test-Path $path) ) 
		{
			New-Item -ItemType Directory -Path $path
			$email = $ADUser.mail
			
			$Acl = Get-Acl $path
			$Ar = New-Object System.Security.AccessControl.FileSystemAccessRule($ADUser.sAMAccountname, "FullControl", "ContainerInherit,ObjectInherit", "None", "Allow")
			$Acl.SetAccessRule($Ar)
			Set-Acl $path $Acl
#            Write-Host $ADUser.sAMAccountname
		}

# KG ændret så der ikke længere tjekkes om bruger er medlem ad gpo.fortrolig
	    $folder = $path + '\Fortrolig Mappe'
        
        if ( -not (Test-Path $folder) ) 
		    {
                New-Item $folder -ItemType Directory -Force
	             #Fjerner nedarvning af rettigheder
		         $acl = Get-ACL -Path $folder
		         $acl.SetAccessRuleProtection($True, $True)
		         (get-item $folder).SetAccessControl($acl)
	             #Fjerner Authenticated Users læse rettigheder
		         $acl = Get-ACL -Path $folder
		         $accessrule = New-Object system.security.AccessControl.FileSystemAccessRule("NT AUTHORITY\Authenticated Users","Read",,,"Allow")
		         $acl.RemoveAccessRuleAll($accessrule)
		         (get-item $folder).SetAccessControl($acl)
            }
    }


	
}