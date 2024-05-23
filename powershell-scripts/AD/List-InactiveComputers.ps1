$devices = @()

foreach ($c in $comps) {
   If ($c.lastlogondate -eq $NULL) {
      $days = 100000
      $lastlogon = (Get-Date).AddYears(-1000)
   }
   else {
      $lastlogon = $c.lastlogondate
      $days = (New-TimeSpan -Start $c.lastlogondate -end $d).Days
   }
   $device = [pscustomobject]@{
                Computername=$c.name;
                Status=$c.enabled;
                LastLogon=$lastlogon;
                LastChanged=$c.whenchanged
                NotSeenForDays=$days
             }
   $devices += $device
}

$devices
