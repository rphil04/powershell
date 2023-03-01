Import-Module ActiveDirectory

# Prompt user to list the AD group
cls
$activeDirectoryGroup = Read-Host "Enter the Active Directory group to remove from the server"

# Prompt user to list the local group
$serverGroup = Read-Host "Enter the local group that the Active Directory group needs to be removed from"

# Prompt user for server search criteria
$serverSearch = Read-Host "Enter the server pattern to search for/update"

# Get the list of servers that match the pattern
$servers = Get-ADComputer -Filter "Name -like '*$serverSearch*'" | select -Property Name

# Have user confirm changes
Write-Host "Servers targets:"
Write-Host "$($servers.name)"
$confirmation = Read-Host "Update membership on the following servers? [y/n]"
if ($confirmation -ne 'y') {
    Write-Host "Operation not confirmed, exiting"
    Sleep -Seconds 5
    Exit
}

foreach ($server in $servers.name) {
    if (!(Test-Connection $server -Count 1 -Quiet)) {
        Write-Host "$($server): Offline"
        Continue
    }

    # Get the list of members currently in the local group
    $serverGroupMembers = Invoke-Command -ComputerName $server -ScriptBlock { Get-LocalGroupMember -Group $using:serverGroup }

    if ($serverGroupMembers.name -notcontains "SFI\$activeDirectoryGroup") {
        Write-Host "$($server): $activeDirectoryGroup is not a member of $serverGroup"
        Continue
    }

    # Get current list of group members
    Write-Host "Server: $($server)"
    Write-Host " "
    Write-Host "Current Group Members: $($serverGroupMembers)"
    Write-Host " "
    Write-Host "Removing group $activeDirectoryGroup from $serverGroup"
    Write-Host " "

    # Remove the AD group from the local server group on the current server
    Invoke-Command -ComputerName $server -ScriptBlock {
        try {
            Remove-LocalGroupMember -Group $using:serverGroup -Member $using:activeDirectoryGroup -ErrorAction Stop
        } catch {
            if ([string]$_.Exception.ErrorCategory -contains "ObjectNotFound") {
                Write-Host "$using:activeDirectoryGroup not found in $using:serverGroup on $($server)"
                Continue
            } else {
                Write-Host $_.Exception
                Continue
            }
        }
    }

    # Get the updated group list
    $newserverGroup = Invoke-Command -ComputerName $server -ScriptBlock { Get-LocalGroupMember -Group $using:serverGroup }
    # Print the server name and the groups it is a member of
    if ($newserverGroup.name -notcontains "SFI\$activeDirectoryGroup") {
        Write-Host " "
        Write-Host "Process Completed Successfully!"
        Write-Host " "
        Write-Host " "
        Write-Host "Server: $($server)"
        Write-Host "Groups: $($newserverGroup)"
        Write-Host " "
    } else {
        Write-Host "Process Failed on $($server)"
        Write-Host " "
    }
}
