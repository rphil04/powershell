# Import Active Directory module
Import-Module ActiveDirectory

# Prompt user to enter the AD group to add to the server
$activeDirectoryGroup = Read-Host "Enter the Active Directory group to add to the server"

# Prompt user to enter the local group to add the AD group to
$serverGroup = Read-Host "Enter the local group that the Active Directory group needs to be added to"

# Prompt user for server search criteria
$serverSearch = Read-Host "Enter the server pattern to search for/update"

# Get the list of servers that match the search pattern
$servers = Get-ADComputer -Filter "Name -like '*$serverSearch*'" | Select-Object -ExpandProperty Name

# Get the list of members currently in the local group on each target server
$localGroupMembers = @{}
foreach ($server in $servers) {
    $localGroupMembers[$server] = Invoke-Command -ComputerName $server -ScriptBlock {
        param($group)
        Get-LocalGroupMember -Group $group
    } -ArgumentList $serverGroup
}

# Display current group members on target systems
foreach ($server in $servers) {
    Write-Host "Current Group Members on $server:" -ForegroundColor DarkBlue -BackgroundColor Yellow
    Write-Host "$($localGroupMembers[$server])"
    Write-Host ""
}

# Perform changes on target systems
foreach ($server in $servers) {
    # Check if server is online
    if (!(Test-Connection $server -Count 1 -Quiet)) {
        Write-Host "$($server): Offline" -ForegroundColor Red
        Continue
    }

    # Script block to perform actions on each remote server
    $scriptBlock = {
        param($group, $adGroup, $targetGroup)
        try {
            # Check if the AD group is already a member of the local group on the current server
            $serverGroupMembers = Get-LocalGroupMember -Group $targetGroup
            if ($serverGroupMembers.Name -contains $adGroup) {
                Write-Host "$env:COMPUTERNAME: $adGroup is already a member of $targetGroup" -ForegroundColor Yellow
            } else {
                Add-LocalGroupMember -Group $targetGroup -Member $adGroup -ErrorAction Stop
                Write-Host "Group added successfully to $targetGroup on $($env:COMPUTERNAME)" -ForegroundColor Green
            }
        } catch {
            Write-Host "Failed to add group to $targetGroup on $($env:COMPUTERNAME): $($_.Exception.Message)" -ForegroundColor Red
        }
    }

    # Invoke the script block on the remote server
    Invoke-Command -ComputerName $server -ScriptBlock $scriptBlock -ArgumentList $serverGroup, "SFI\$activeDirectoryGroup", $serverGroup
}

Write-Host "Script execution completed."
