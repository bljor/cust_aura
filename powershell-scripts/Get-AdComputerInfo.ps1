
param (
    [Parameter(Mandatory=$false)]
    $computers
    [Parameter(Mandatory=$false)]
    [switch]$ConnectToComputer=$false
)

$expComp = ""
$res=""
$comps = @()

If ($ConnectToComputer -eq 'True') {
    $cred = Get-Credential -Message "Indtast oplysninger på den bruger, der skal bruges ved forbindelse til remote computer"
}

If ($computers.count -gt 0) {
    ForEach ($c in $computers) {
        $comp = get-adcomputer $c -properties Cn,Created,IPv4Address,LastLogonDate,Modified,OperatingSystem,PasswordLastSet,DistinguishedName
        $res = Test-NetConnection -ComputerName $comp.Cn -WarningAction SilentlyContinue -InformationLevel Detailed

        If (($ConnectToComputer -eq 'True') -and ($cred)) {
            If ($res.PingSucceeded -eq 'True') {
                $info = Invoke-Command -ComputerName $comp.cn -Credential $cred -ScriptBlock {Get-ComputerInfo}
            }
        }

        $expComp = [pscustomobject]@{
            Name=$comp.Cn
            Created=$comp.Created
            IPv4Address=$comp.IPv4Address
            LastLogonDate=$comp.LastLogonDate
            Modified=$comp.Modified
            OperatingSystem=$comp.OperatingSystem
            PasswordLastSet=$comp.PasswordLastSet
            DistinguishedName=$comp.DistinguishedName
            IpFromDns=$res.RemoteAddress
            PingSucceeded=$res.PingSucceeded
        }
        Write-Host "Computer: " $comp.cn " " $res.PingSucceeded
        $comps += $expComp
        $res=""
    }
} else {
    write-host "Kan ikke identificere antal computere"
}
Write-Host "Antal computere: " $comps.count
$comps | export-csv -path c:\temp\computer_info.csv -NoTypeInformation
