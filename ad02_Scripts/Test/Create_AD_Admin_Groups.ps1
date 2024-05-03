<# 
# ------------------------------------------------------------------------------------------#
# Date: 19/11-2021
# Purpose: Add AD Group to local Administrators group 
# Author: JEH
# Changed - date: 
# Source: IT-Core
# ------------------------------------------------------------------------------------------#
#>

Start-Transcript -Path "C:\Scripts\AD\Log\AddADGroupToLocalAdminstrators.txt" -Append



#$cred = (Get-Credential)
$servers = Get-ADComputer -Filter 'operatingsystem -like "*server*" -and enabled -eq "true"' -Properties Name,DNSHostName | Select-Object @{Label="Name";Expression={$_.Name.ToLower()}},@{Label="DNSHostName";Expression={$_.DNSHostName.ToLower()}}

Foreach ($server in $servers[10]) 
{
    $GroupName = "$($server.Name)-Admin"
    $OUPath    = "OU=Server Admin Users,OU=AURA Groups,DC=aura,DC=dk"

    if (!(Get-ADGroup $GroupName))
    {
        Write-Verbose "Create group: $GroupName in OU: $OUPath"
        New-ADGroup -DisplayName $GroupName -GroupScope Global -GroupCategory Security -Name $GroupName -Path $OUPath -SamAccountName "$groupName"
        Write-Host "Group created: $GroupName in OU: $OUPath"
    }
    else
    {
        Write-Warning "Group already exists"
    }
}

Foreach ($server in $servers[10])
{
    $GroupName = "$($server.Name)-Admin"
    
    Invoke-Command -ComputerName $server.DNSHostName -ScriptBlock {
        Param ($server)
        $adminGroup = Get-LocalGroup -SID "S-1-5-32-544"
        Add-LocalGroupMember -Group $adminGroup -Member "$server-Admin" -Confirm:$false
    } -ArgumentList $server.Name <#-Credential $Cred #>
}

Stop-Transcript
Write-Host "Script finished, check log file."