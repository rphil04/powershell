<#
.SYNOPSIS
This script retrieves events from a specified Windows event log on a remote computer based on a 
specified event ID, and outputs the results to the console.

.DESCRIPTION
This script prompts the user to enter the name of a remote computer, the event ID to search for, 
and the name of the log to search in. It then retrieves events from the specified log on the 
remote computer that match the specified event ID, and outputs information about each event to 
the console. If no events are found, a message is output to the console indicating that.

.PARAMETER ComputerName
The name of the remote computer to retrieve events from.

.PARAMETER EventID
The ID of the event to search for in the specified log.

.PARAMETER LogName
The name of the log to search for the specified event ID.
#>

#Load RSAT
Import-Module ActiveDirectory

# Clear the screen
Clear-Host

# Prompt the user to enter the hostname of the remote computer
$computerName = Read-Host "Enter the name of the remote computer"

# Prompt the user to enter the event ID to search for
$eventID = Read-Host "Enter the event ID to search for"

# Prompt the user to enter the name of the log to search in
$logName = Read-Host "Enter the name of the log to search in"

# Output a prompt indicating that information is being gathered
Write-Host " "
Write-Host "Please wait... gathering information"

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
