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

# Get the list of members currently in the local group
$localGroupMembers = @{}
foreach ($server in $servers) {
    $localGroupMembers[$server] = Invoke-Command -ComputerName $server -ScriptBlock {
        param($group)
        Get-LocalGroupMember -Group $group
    } -ArgumentList $serverGroup
}

# Display current group members
Write-Host "Current Group Members:" -ForegroundColor DarkBlue -BackgroundColor Yellow
Write-Host "$($serverGroupMembers)"
Write-Host ""

# Confirm the changes with the user
Write-Host "Servers to be updated:" -ForegroundColor DarkBlue -BackgroundColor Yellow
Write-Host "$($servers)"
Write-Host ""

$confirmation = Read-Host "Update membership on the listed servers? [y/n]"
if ($confirmation -ne 'y') {
    Write-Host "Operation not confirmed, exiting"
    Start-Sleep -Seconds 5
    exit
}

foreach ($server in $servers) {
    # Check if server is online
    if(!(Test-Connection $server -Count 1 -Quiet)){
        Write-Host "$($server): Offline"
        Continue
    }

    # Get the list of members currently in the local group on the current server
    $serverGroupMembers = Get-LocalGroupMember -Group $serverGroup

    # Check if the AD group is already a member of the local group on the current server
    if($serverGroupMembers.Name -contains "SFI\$activeDirectoryGroup"){
        Write-Host "$($server): $activeDirectoryGroup is already a member of $serverGroup"
        Continue
    }

    # Display the current list of group members on the current server
    Write-Host "Server: $($server)"
    Write-Host "Current Group Members: $($serverGroupMembers)"
    Write-Host "Adding group $activeDirectoryGroup to $serverGroup"

    # Add the AD group to the local server group on the current server
    try {
        Add-LocalGroupMember -Group $serverGroup -Member "SFI\$activeDirectoryGroup" -ErrorAction Stop
        Write-Host "Group added successfully to $serverGroup on $($server)"
    } catch {
        Write-Host "Failed to add group to $serverGroup on $($server): $($_.Exception.Message)"
    }

    # Get the updated list of group members on the current server
    $newServerGroup = Get-LocalGroupMember -Group $serverGroup

    # Display the updated list of group members on the current server
    Write-Host "New Group Members: $($newServerGroup)"
    Write-Host ""
}

Write-Host "Script execution completed."
