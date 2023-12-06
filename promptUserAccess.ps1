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

foreach ($server in $servers) {
    # Check if server is online
    if(!(Test-Connection $server -Count 1 -Quiet)){
        Write-Host "$($server): Offline"
        Continue
    }

    # Script block to perform actions on each remote server
    $scriptBlock = {
        param($group, $adGroup, $targetGroup)
        try {
            # Check if the AD group is already a member of the local group on the current server
            $serverGroupMembers = Get-LocalGroupMember -Group $targetGroup
            if($serverGroupMembers.Name -contains $adGroup){
                Write-Host "$env:COMPUTERNAME: $adGroup is already a member of $targetGroup"
            } else {
                Add-LocalGroupMember -Group $targetGroup -Member $adGroup -ErrorAction Stop
                Write-Host "Group added successfully to $targetGroup on $($env:COMPUTERNAME)"
            }
        } catch {
            Write-Host "Failed to add group to $targetGroup on $($env:COMPUTERNAME): $($_.Exception.Message)"
        }
    }

    # Invoke the script block on the remote server
    Invoke-Command -ComputerName $server -ScriptBlock $scriptBlock -ArgumentList $serverGroup, "SFI\$activeDirectoryGroup", $serverGroup
}

Write-Host "Script execution completed."
