
#Laver en top html fil
Copy-Item \\aura.dk\Services\Deployment\@log\backup\backup.htm.txt \\aura.dk\Services\Deployment\@log\backup\backup.html -force

<#--Hyperv servere
$servers = "Hyperv02","Hyperv06","Hyperv-Netbas"
foreach($s in $servers)
{
$s
$path = "\\$s\baclient$\dsmsched.log"
$FileExists = Test-Path $path
    If ($FileExists -eq $True) 
        {
                $lastline = (Get-Content $path)[-1]
                     If ($lastline.Length -lt 5)
                    {
                       $lastline = (Get-Content $path)[-2]
                    }

                    
                     if ($lastline.Substring(0,10) -contains '*/*')
                    {
                       $lastline = (Get-Content $path)[-6]
                       write-host "2"  $lastline.Substring(0,10)
                    }

                   
                $lastline = $lastline.Substring(0,10)
                $today = (Get-Date).ToString('MM\/dd\/yyyy')
                $yesterday = (Get-Date).AddDays(-1).ToString('MM\/dd\/yyyy')
                If ($lastline -eq $yesterday -or $lastline -eq $today)
                    {
                        $temp = get-content $path | select-string -pattern "Total number of virtual machines failed:" | select -last 1
                        $line = $temp
                             If (!$temp)
                                  {
                                      Add-Content -Value "<tr><th>$s</th><th><font color=red> FEJL !</font></th></tr>" -Path \\aura.dk\Services\Deployment\@log\backup\backup.html
                                  }
                        $temp = $s + " - " + $temp 
                        If ($temp.Split()[-1] -gt '0')
                            {
                                $antal = $temp.Split()[-1]
                                $i = 0
                                $temp = $temp + "`n`n"
                                while ($i -lt $antal)
                                    {
                                        $i++
                                        $ll = (get-content $path -TotalCount ($line.LineNumber+$i))[-1]
                                        $temp = $temp + $ll.Split()[-1] + " `n"
                                    }
                              send-mailmessage -SmtpServer smtprelay.aura.dk -Priority High -to "it@aura.dk" -from "BACKUP <it@aura.dk>" -subject "Backup Fejl!! $s"  -body $temp
                              Add-Content -Value "<tr><th>$s</th><th><font color=red> $antal Fejlet !</font></th></tr>" -Path \\aura.dk\Services\Deployment\@log\backup\backup.html
                            }

                        If ($temp.Split()[-1] -eq '0')
                            {
                               # send-mailmessage -SmtpServer smtprelay.aura.dk -to "it@aura.dk" -from "BACKUP <it@aura.dk>" -subject "Backup OK $s" 
                                Add-Content -Value "<tr><th>$s</th><th><font color=green>OK</font></th></tr>" -Path \\aura.dk\Services\Deployment\@log\backup\backup.html
                            }
                        Add-Content \\aura.dk\services\Deployment\@log\backup\backup.txt  "$temp`n"
                        $temp = get-content $path | select-string -pattern "Total number of virtual machines processed:" | select -last 1
                        $temp = $s + " - " + $temp
                        Add-Content \\aura.dk\services\Deployment\@log\backup\backup.txt  "$temp`n"
                    }

                    Else
                        {
                            send-mailmessage -SmtpServer smtprelay.aura.dk -Priority High -to "it@aura.dk" -from "BACKUP <it@aura.dk>" -subject "Backup Fejl!! $s"  -body "Loggen er for gammel $lastline"
                            Add-Content -Value "<tr><th>$s</th><th><font color=red>Loggen er for gammel $lastline</font></th></tr>" -Path \\aura.dk\Services\Deployment\@log\backup\backup.html
                        }
        }
    Else 
        {
            send-mailmessage -SmtpServer smtprelay.aura.dk -Priority High -to "it@aura.dk" -from "BACKUP <it@aura.dk>" -subject "Backup Fejl!! $s"  -body "Ingen dsmsched.log"
            Add-Content -Value "<tr><th>$s</th><th><font color=red>Ingen log !</font></th></tr>" -Path \\aura.dk\Services\Deployment\@log\backup\backup.html
        }
}

--#>



#Filprint og SQL servere
$servers = "DB-SQL-IT","VE-DB-ARTESA"

foreach($s in $servers)
{
$s
$path = "\\$s\baclient$\dsmsched.log"
$FileExists = Test-Path $path
    If ($FileExists -eq $True) 
        {
                $lastline = (Get-Content $path)[-1]
                     If ($lastline.Length -lt 5)
                    {
                       $lastline = (Get-Content $path)[-2]
                    }

                    
                     if ($lastline.Substring(0,10) -contains '*/*')
                    {
                       $lastline = (Get-Content $path)[-6]
                       write-host "2"  $lastline.Substring(0,10)
                    }

                   
                $lastline = $lastline.Substring(0,10)
                $today = (Get-Date).ToString('MM\/dd\/yyyy')
                $yesterday = (Get-Date).AddDays(-1).ToString('MM\/dd\/yyyy')
                    If ($lastline -eq $yesterday -or $lastline -eq $today)
                        {
                            Add-Content -Value "<tr><th>$s</th><th><font color=green>OK</font></th></tr>" -Path \\aura.dk\Services\Deployment\@log\backup\backup.html
                        }
                    Else
                        {
                            send-mailmessage -SmtpServer smtprelay.aura.dk -Priority High -to "it@aura.dk" -from "BACKUP <it@aura.dk>" -subject "Backup Fejl!! $s"  -body "Loggen er for gammel $lastline"
                            Add-Content -Value "<tr><th>$s</th><th><font color=red>Loggen er for gammel $lastline</font></th></tr>" -Path \\aura.dk\Services\Deployment\@log\backup\backup.html
                        }

        }
    Else
        {
            send-mailmessage -SmtpServer smtprelay.aura.dk -Priority High -to "it@aura.dk" -from "BACKUP <it@aura.dk>" -subject "Backup Fejl!! $s"  -body "Ingen dsmsched.log"
            Add-Content -Value "<tr><th>$s</th><th><font color=red>Ingen log !</font></th></tr>" -Path \\aura.dk\Services\Deployment\@log\backup\backup.html
        }
}

 #footer til html fil

Add-Content \\aura.dk\services\Deployment\@log\backup\backup.txt  "<-------------------------------------------------------------------------->`n"
$Time = get-date
Add-Content -Value "</table><br> <center>    $Time" -Path \\aura.dk\Services\Deployment\@log\backup\backup.html
Copy-Item \\aura.dk\Services\Deployment\@log\backup\backup.html \\mgmt01.aura.dk\prtg\backup.htm -force