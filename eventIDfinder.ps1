$computerName = "REMOTECOMPUTERNAME"
$computerID = "SPECIFICCOMPUTERID"

$found = $false

$computers = Get-ADComputer -Filter {OperatingSystem -like "*Windows*"} -Property Name | Select-Object -ExpandProperty Name

foreach ($computer in $computers) {
    if ($computer -eq $computerName) {
        $found = $true
        $computerInfo = Get-WmiObject Win32_ComputerSystem -ComputerName $computer | Select-Object -ExpandProperty UserName
        if ($computerInfo -like "*$computerID*") {
            Write-Host "Computer ID $computerID found on $computerName"
        } else {
            Write-Host "Computer ID $computerID not found on $computerName"
        }
        break
    }
}

if (!$found) {
    Write-Host "Computer $computerName not found"
}
