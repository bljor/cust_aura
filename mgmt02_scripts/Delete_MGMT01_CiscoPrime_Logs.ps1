#Deleting logfile from MGMT01 Cisco Prime Logs. 

$servers         = @("MGMT01")
$filedestination = @("C$\Users\serviceuser\Prime")
$DaysToKeep      = 45

Function GetData {
    param(
        [parameter(ValueFromPipeline=$true)]$server, 
        $filedestination
    )
    Begin {
        $Files = @()
    }
    Process {
        $path = "\\$server\$filedestination"
        $Files += Get-ChildItem $path -file |select LastWriteTime, FullName   
    
    }
    End {
        Return $Files
    }
}

Function SortData {
    param(
        [parameter(ValueFromPipeline=$true)]$data,
        $DaysToKeep
    )
    Begin {
        $SortedData = @()
    }
    Process {
        $sortedData += $data | Where {$_.LastWriteTime -le (get-date).AddDays(-$DaysToKeep) }
    }
    End {
        Return $SortedData
    }

}

Function DeleteData {
    param(
        [parameter(ValueFromPipeline=$true)]$sortedData
    )
    
    Process {
        Remove-Item -Path $sortedData -Force
    }

 
}



$Files  = $servers | GetData -filedestination $filedestination
$Files1 = $Files   | SortData -DaysToKeep $DaysToKeep | select -ExpandProperty FullName 
$Files1            | DeleteData 