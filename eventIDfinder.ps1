$computerName = "REMOTECOMPUTERNAME"
$eventID = "SPECIFICEVENTID"

$found = $false

$events = Get-WinEvent -ComputerName $computerName -FilterHashtable @{LogName='System';ID=$eventID} -MaxEvents 10 | Select-Object -Property TimeCreated,Message

foreach ($event in $events) {
    $found = $true
    Write-Host "Event ID $eventID found on $computerName at $($event.TimeCreated):"
    Write-Host $event.Message
}

if (!$found) {
    Write-Host "Event ID $eventID not found on $computerName"
}
