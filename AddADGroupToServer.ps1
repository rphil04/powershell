# Import the ActiveDirectory module
Import-Module ActiveDirectory

# Prompt user for the name of the Active Directory group to add to the server
$activeDirectoryGroup = Read-Host "Enter the Active Directory group to add to the server"

# Prompt user for the name of the local group to add the AD group to
$serverGroup = Read-Host "Enter the local group that the Active Directory group needs to be added to"

# Prompt user for server search criteria
$serverSearch = Read-Host "Enter the server pattern to search for/update"

# Get a list of servers that match the specified pattern
$servers = Get-ADComputer -Filter "Name -like '*$serverSearch*'" | Select-Object -ExpandProperty Name

# Confirm the list of servers to update
Write-Host "Servers to update:"
Write-Host "$servers"
$confirmation = Read-Host "Update membership on the following servers? [y/n]"
if ($confirmation -ne 'y') {
    Write-Host "Operation not confirmed, exiting"
    Start-Sleep -Seconds 5
    Exit
}

# Loop through the list of servers and update the local group
foreach ($server in $servers) {

    # Skip servers that are offline
    if (!(Test-Connection $server -Count 1 -Quiet)) {
        Write-Host "${server}: Offline"
        continue
    }

    # Get the list of members currently in the local group
    $serverGroupMembers = Invoke-Command -ComputerName $server -ScriptBlock { Get-LocalGroupMember -Group $using:serverGroup }

    # Check if the AD group is already a member of the local group
    if ($serverGroupMembers.Name -contains "SFI\${activeDirectoryGroup}") {
        Write-Host "${server}: ${activeDirectoryGroup} is already a member of ${serverGroup}"
        continue
    }

    # Display the current group membership for the local group
    Write-Host "Server: $server"
    Write-Host ""
    Write-Host "Current Group Members: $($serverGroupMembers.Name)"
    Write-Host ""

    # Add the AD group to the local group on the current server
    try {
        Invoke-Command -ComputerName $server -ScriptBlock {
            Add-LocalGroupMember -Group $using:serverGroup -Member $using:activeDirectoryGroup -ErrorAction Stop
        }
    } catch {
        if ($_.Exception.ErrorCategory -contains "ResourceExists") {
            Write-Host $_.Exception
            continue
        } else {
            Write-Host $_.Exception
            continue
        }
    }

    # Get the updated group membership for the local group
    $newServerGroup = Invoke-Command -ComputerName $server -ScriptBlock { Get-LocalGroupMember -Group $using:serverGroup }

    # Display the updated group membership for the local group
    if ($newServerGroup.Name -contains "SFI\${activeDirectoryGroup}") {
        Write-Host ""
        Write-Host "Process Completed Successfully!"
        Write-Host ""
        Write-Host "Server: $server"
        Write-Host "Groups: $($newServerGroup.Name)"
        Write-Host ""
    } else {
        Write-Host "Process Failed on $server"
        Write-Host ""
    }
}
