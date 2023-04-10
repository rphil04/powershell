# Prompt the user to enter the hostname of the remote computer
$computerName = Read-Host "Enter the name of the remote computer"

# Prompt the user to enter the event ID to search for
$eventID = Read-Host "Enter the event ID to search for"

# Prompt the user to enter the name of the log to search in
$logName = Read-Host "Enter the name of the log to search in"

try {
    # Retrieve events from the specified log on the remote computer
    $events = Get-WinEvent -ComputerName $computerName -FilterHashtable @{LogName=$logName;ID=$eventID} -MaxEvents 10 -ErrorAction Stop
    
    # Set a flag to track whether any events were found
    $found = $false
    
    # Loop through each event returned by Get-WinEvent
    foreach ($event in $events) {
        # If at least one event is found, set the flag to true
        $found = $true
        
        # Split the event message into separate lines and trim whitespace
        $messageLines = $event.Message -split "`r`n"
        $formattedMessage = $messageLines | ForEach-Object { $_.Trim() }
        
        # Create a custom object to hold the event information and output it
        $output = [pscustomobject] @{
            ComputerName = $computerName
            EventID = $eventID
            LogName = $logName
            TimeCreated = $event.TimeCreated
            Message = $formattedMessage
        }
        Write-Output $output
    }
    
    # If no events were found, output a message indicating that
    if (!$found) {
        Write-Host "Event ID $eventID not found on $computerName in $logName log"
    }
}
catch {
    # If an error occurs, output an error message
    Write-Error "Error occurred while retrieving events: $_"
}
