<#===========================================================================================================================
 Script Name: MonitorADAdminsRemove.ps1
 Description: It sends you Notification email if any user is added to any  Domain admins, schema admins or enterprise admins Groups.
      Inputs: Path of folder or drive where HTML report will be create, email sent to and received and SMTP settings.
     Outputs: HTML report of user added to Admin group and performed by.
       Notes: Make sure to create task on all the domain controllers if you have and Active directory Audit is enabled.
      Author: Jiten https://community.spiceworks.com/people/jitensh
Date Created: 1/19/2018
     Credits: 
Last Revised: 1/23/2018
=============================================================================================================================
Instructions
------------

1> Download the script and place it under c:\scripts\ folder, please follow the link below to be able to create a task.
2> https://community.spiceworks.com/how_to/17736-run-powershell-scripts-from-task-scheduler
3> Make sure On Trigger you select ON an event > Log; Security > Source; Microsoft Windows security auditing > eventid;4728.

################################################################***** ##################################################################>

#@@@@@@@@@> Please Modify below  <@@@@@@###

$reportpath= "c:\scripts\report-removed.html"

$to="itadmins@aura.dk"
$from="it@aura.dk"
$smtp="smtprelay.aura.dk"

#@@@@@@@@@> Modification ends here @@@@@@###

$Style = @"
<style>
BODY{font-family:Calibri;font-size:12pt;}
TABLE{border-width: 1px;border-style: solid;border-color: black;border-collapse: collapse; padding-right:5px}
TH{border-width: 1px;padding: 5px;border-style: solid;border-color: black;color:black;background-color:#FFFFFF }
TH{border-width: 1px;padding: 5px;border-style: solid;border-color: black;background-color:Green}
TD{border-width: 1px;padding: 5px;border-style: solid;border-color: black}
</style>
"@

If ( ! (Get-module ActiveDirectory )) {
Import-Module ActiveDirectory
Cls
}
$events02 = Get-WinEvent -FilterHashtable @{logname='Security'; ID=4729; } -MaxEvents 1 
$names = 'MemberSid', 'TargetUserName', 'SubjectUserName'

$events02 | ForEach-Object {
    ([xml]$_.ToXml()).Event.EventData | ForEach-Object {
        $props = @{}

        $_.Data |
            Where-Object { $names -contains $_.Name } |
            ForEach-Object { $props[$_.Name] = $_.'#text' }

       $props= New-Object -Type PSObject -Property @{
        User=(Get-AdUser $props.MemberSid).Name
        Removedby=$props.subjectusername
        RemovedFrom=$props.TargetUserName

        }
        
    }
}

$props |select User,Removedby,RemovedFrom  | ConvertTo-Html   -body "<H2>Find The Following Details</H2>"-Head $style| Out-File $reportpath


$body = [System.IO.File]::ReadAllText("$reportpath")


#### Modify who email will be sent and received.

$MailMessage = @{ 
    To = $to
    From = $from
    Subject = "Attention a user is removed from Administrative Group " 
    Body = "$body" 
    priority="high"
    Smtpserver = $smtp
    ErrorAction = "SilentlyContinue" 
}
Send-MailMessage @MailMessage -bodyashtml