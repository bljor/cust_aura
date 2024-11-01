import-module psTerminalServices
Import-Module ActiveDirectory
#Add-WindowsFeature RSAT-AD-PowerShell

#Udvælger bruger som er medlem af en bestem AD gruppe.
$group = "DAX.Eksterne.Brugere"
$members = Get-ADGroupMember -Identity $group -Recursive | Select -ExpandProperty Samaccountname
$members=$members.ToLower()

#Hvor lang tid skal man være disconnected
$date = (Get-date).AddMinutes(-5)

#Henter RDP sessions som er disconnected i mere end $Date
$Sessions = get-tssession | where {(($_.state -eq "Disconnected") -and ($_.useraccount -like "AURA\*") -and ($_.disconnecttime -lt $date))} 

#Test hver RDP session, er DAX Ax32.exe bliver den stoppet
foreach ($session in $sessions)
    {
         $user = $session.Username |Foreach {$_ -replace "AURA\\", ""} 
        If ($members -contains $user.ToLower()) 
            {
               $procid = Get-WmiObject win32_process | Where-Object {$_.description -eq "Ax32.exe"} | Where-Object {$_.sessionID -eq $session.sessionid } | select ProcessId
               #Tester om der er mere end 1 dax kørende, så vælgere den den første.
               if ($procid.count -gt 1)
                    {
                        $procid = $procid[0]  
                    }
               #Hvis der er en Ax32.exe kørende bliver den stoppet og skrevet i loggen.
               if (-not ([string]::IsNullOrEmpty($procid)))
                   {
                        $tid = Get-date
                        Stop-Process -Force -Confirm:$false -Id $procid.ProcessId
                        Add-content c:\script\log.txt -value "$tid $user"
                   }
            }
    }