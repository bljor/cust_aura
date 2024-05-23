$Devices = @()

$c = ""
$comps = ""
$device = ""
$comps = Get-AdComputer -Filter * -Properties *
$days = ""
$lastlogon = ""

ForEach ($c in $comps) {
   If ($c.lastlogondate -eq $NULL) {
      $days = 100000
      $lastlogon = (Get-Date).AddYears(-1000)
   }
   else {
      $lastlogon = $c.lastlogondate
      $days = (New-TimeSpan -Start $c.lastlogondate -end $d).Days
   }
   $Device = [pscustomobject]@{
                Computername=$c.name;
                Status=$c.enabled;
                LastLogon=$lastlogon;
                LastChanged=$c.whenchanged
                NotSeenForDays=$days
             }
   $Devices += $device
   $Days = 0
   $Lastlogon = ""
}

$Devices
