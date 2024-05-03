
$Driver = Start-SeFirefox 
Enter-SeUrl https://office.etrack1.com/nfo/Login.aspx -Driver $Driver

$Element = Find-SeElement -Driver $Driver -Id "user"
Send-SeKeys -Element $Element -Keys "wit@aura.dk"

$Element = Find-SeElement -Driver $Driver -Id "password"
Send-SeKeys -Element $Element -Keys "System/1"

$Element = Find-SeElement -Driver $Driver -Id "login_form"
$Element.Submit()

sleep 10

$Driver.PageSource | Out-File -FilePath c:\temp\web.txt 

$data = Get-Content "c:\temp\web.txt "
$num = ""                           
foreach ($line in $data)
    {
    if ($line -like "*1 til*")
        {
            $num = $line
             $num
           break
        }
    
    Else 
        {
            $num = "?"
        } 
    }
	
	$result = $num.Split(' ')[-1]

	$Driver.Close()
	Get-Process geckodriver -ErrorAction SilentlyContinue | Foreach-Object { $_.Kill() }
	
	if ([string]($result -as [int]) )
{
Copy-Item \\mgmt01.aura.dk\prtg\etrack-tom.txt \\mgmt01.aura.dk\prtg\etrack.htm  
start-sleep 4
$result | Out-File \\mgmt01.aura.dk\prtg\etrack.htm -Append -Encoding UTF8
$result | Out-File \\mgmt01.aura.dk\prtg\etrack.txt -force
}