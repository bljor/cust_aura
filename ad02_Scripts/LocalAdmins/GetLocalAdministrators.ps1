<#
######################################################################
#                                                                    #
#                         Created By IT-Core                         #
#                          Date 27/06-2022                           #
#                    Jonathan Soegaard - jols@itcore.dk              #
#                            Version 1.0                             #
######################################################################
#>

Import-Module ActiveDirectory

$logPath        = "C:\temp\serverGroups"
$servers        = Get-ADComputer -LDAPFilter "(OperatingSystem=*Server*)" | Where-Object {$_.DistinguishedName -notlike "*OU=Domain Controllers*"} | Select-Object -ExpandProperty Name
$adminCsv       = "C:\temp\administrators\admins.txt"

function Add-Log 
{
    param
    (
        [parameter(mandatory=$true,valuefrompipeline=$true)]
        [string]$message,

        [parameter(mandatory=$false)]
        [validateSet("verbose","information","warning","error")]
        [string]$level
    )

    Begin
    {
        If (!(Test-Path $logPath))
        {
            New-Item $logPath -ItemType Directory -Force | Out-Null
        }
    }
    Process
    {
        $timeFormat   = "[HH':'mm':'ss.fff]':'"
        $date         = Get-Date -Format $timeFormat
        $operationLog = "$logPath\operation.log"
        $errorLog     = "$logPath\error.log"

        switch ($level)
        {
            "verbose"
            {
                $datemessage = "$date VERBOSE:`t`t $message"
                Write-Host $datemessage -ForegroundColor Cyan
                Add-Content -Value $datemessage $operationLog
            }
            "information"
            {
                $datemessage = "$date INFORMATION:`t $message"
                Write-Host "$datemessage" -ForegroundColor Green
                Add-Content -Value $datemessage $operationLog
            }
            "warning"
            {
                $datemessage = "$date WARNING:`t`t $message"
                Write-Host "$datemessage" -ForegroundColor Yellow
                Add-Content -Value $datemessage $operationLog
                Add-Content -Value $datemessage $errorLog
            }
            "error"
            {
                $datemessage = "$date ERROR:`t $message"
                Write-Host "$datemessage" -ForegroundColor Red
                Add-Content -Value $datemessage $errorLog
            }
        }
    }
}

Function Get-RespondingServers
{
    param
    (
        [parameter(mandatory=$true,valuefrompipeline=$true)]
        [string]$server,

        [parameter(mandatory=$true)]
        [int]$count
    )
    
    begin
    {
        $progress = 1
        $result = @()
    }
    process
    {
        $percentage = $progress / $count * 100
        Write-Progress -Activity "Progressing $progress/$count - testing network connection to server: $($server)" -Status "$percentage% Complete" -PercentComplete $percentage

        if (Test-Port -Computer $server -Port 5985 -Millisecond 500)
        {
            Add-Log -message "Server: $server is responding" -level information
            $result += $server
        }
        else
        {
            Add-Log -message "Server: $server is NOT responding" -level warning
        }

        $progress++
    }
    end
    {
        return $result
    }
}

function Test-Port
{
    param 
    ( 
        [parameter(mandatory=$true)]
        [string]$Computer, 
        
        [parameter(mandatory=$true)]
        [int]$Port,

        [parameter(mandatory=$false)]
        [int]$Millisecond = 300 
    )
 
    $Test = New-Object -TypeName Net.Sockets.TcpClient
 
    ($Test.BeginConnect($Computer,$Port,$Null,$Null)).AsyncWaitHandle.WaitOne($Millisecond)
    $Test.Close()
}

function Get-LocalAdministrators
{
    param
    (
        [parameter(mandatory=$true,valuefrompipeline=$true)]
        [string]$server
    )

    begin
    {
        $result = @()
    }
    process
    {
        $localGroupname = "administrat*"

        $result += Invoke-Command -ComputerName $server -ScriptBlock {
            param
            (
                [string]$server,

                [string]$localGroup
            )

            try
            {
                $result = @()

                $group   = Get-LocalGroup $localGroup

                try
                {
                    $members = Get-LocalGroupMember -Group $group -ErrorAction SilentlyContinue
                }
                catch
                {
                    $members = @(
                        ([ADSI]"WinNT://./$group").psbase.Invoke('Members') | Foreach-Object { 
                            $_.GetType().InvokeMember('AdsPath','GetProperty',$null,$($_),$null) 
                        }) -match '^WinNT' -replace "WinNT://"
                }
            }
            catch
            {
                Write-Error -message "Error getting group members on server: $server - $_"
            }

            if ($members)
            {
                $obj = New-Object -TypeName PSObject
                $obj | Add-Member -NotePropertyName "server" -NotePropertyValue $server
                $obj | Add-Member -NotePropertyName "members" -NotePropertyValue $members
                $result += $obj

                return $result
            }
            else
            {
                Write-Error -Message "Error - members does not have a value!" 
            }
        } -ArgumentList $server, $localGroupname
    }
    end
    {
        return $result | Select-Object server,members
    }
}

function Get-RecursiveMembers 
{
    param
    (
        [parameter(mandatory=$true,valuefrompipeline=$true)]
        $serverMembers
    )

    Begin
    {
        $result = @()
    }
    Process
    {
        $adMembers = $serverMembers.Members | Where-Object {$_.PrincipalSource -eq "ActiveDirectory"}
        $obj       = New-Object -TypeName PSObject
        $obj | Add-Member -MemberType NoteProperty -Name "Server" -Value $serverMembers.server
        $obj | Add-Member -MemberType NoteProperty -Name "Administrators" -Value @()

        foreach ($adMember in $adMembers)
        {
            [string]$objectName = $adMember.Name -replace '.*\\'
            
            if ($adMember.ObjectClass -eq "User")
            {
                $ADUser = Get-ADUser $objectName | Select-Object Enabled,Name,SamAccountName,UserPrincipalName,@{Name = "Source"; Expression = { "Direct_Added" }}

                Add-Log -message "User: $($ADUser.SamAccountName) is local administrator on server: $($serverMembers.server) Source: Direct_Added" -level information

                $obj.Administrators += $ADUser

            }
            elseif ($adMember.ObjectClass -eq "Group")
            {
                $groupMembers = Get-ADGroupMember $objectName -Recursive
            
                foreach ($member in $groupMembers)
                {
                    $ADUser = Get-ADUser $member.Name | Select-Object Enabled,Name,SamAccountName,UserPrincipalName,@{Name = "Source"; Expression = { $objectName }}
                    
                    Add-Log -message "User: $($ADUser.SamAccountName) is local administrator on server: $($serverMembers.server) Source: $objectName" -level information

                    $obj.Administrators += $ADUser
                }
            }
        }
        
        $result += $obj
    }
    End
    {
        return $result
    }
}

Function Get-PrettyFormat
{
    param
    (
        [parameter(mandatory=$true,ValueFromPipeline=$true)]
        [object[]]$serverGroups,

        [parameter(mandatory=$true)]
        [string]$path
    )

    Begin
    {
        $result = @()
        $csv = "Server,Name,SamAccountName,UserPrincipalName,Enabled,Source`n"
    }
    Process
    {
        Foreach ($user in $serverGroups.administrators)
        {
            $csv += "$($serverGroups.Server), $($user.Name), $($user.SamAccountName),$($user.UserPrincipalName),$($user.Enabled),$($user.Source)`n"
        }
    }
    End
    {
        Add-Log -message "Csv file has been generated: $path" -level information
        Set-Content -Value $csv -Path $path
    }
}

Add-Log -message "Found a total of $($servers.Count) servers" -level information
$respondingServers   = $servers | Get-RespondingServers -count $servers.Count
$serverMembers       = $respondingServers | Get-LocalAdministrators
$localAdministrators = $serverMembers | Get-RecursiveMembers
$localAdministrators | Get-PrettyFormat -path $adminCsv