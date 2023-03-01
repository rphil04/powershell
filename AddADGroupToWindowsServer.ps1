# Import the Active Directory module
Import-Module ActiveDirectory

# Prompt the user to enter the Active Directory group
$activeDirectoryGroup = Read-Host "Enter the Active Directory group to add to the server"

# Prompt the user to enter the local group
$serverGroup = Read-Host "Enter the local group that the Active Directory group needs to be added to"

# Prompt the user to enter the server search criteria
$serverSearch = Read-Host "Enter the server pattern to search for/update"

# Get the list of servers that match the server search pattern
$servers = Get-ADComputer -Filter "Name -like '*$serverSearch*'" | select -Property Name

# Display the list of servers to be updated and prompt for confirmation
Write-Host "Servers targets:"
Write-Host "$($servers.name)"
$confirmation = Read-Host "Update membership on the following servers? [y/n]"
if ($confirmation -ne 'y') {
    Write-Host "Operation not confirmed, exiting"
    sleep -Seconds 5
    exit
}

# Loop through each server and add the Active Directory group to the local group on the server
foreach ($server in $servers.name) {

    # Check if the server is online before attempting to modify the group membership
    if(!(Test-Connection $server -Count 1 -Quiet)){
        Write-Host "$($server): Offline"
        continue
    }

    # Get the list of members currently in the local group on the server
    $serverGroupMembers = Invoke-Command -ComputerName $server -ScriptBlock {Get-LocalGroupMember -Group $using:serverGroup}

    # Check if the Active Directory group is already a member of the local group on the server
    if($serverGroupMembers.name -contains "SFI\$activeDirectoryGroup"){
        Write-Host "$($server): $activeDirectoryGroup is already a member of $serverGroup"
        continue
    }

    # Display the current group members and add the Active Directory group to the local group on the server
    Write-Host "Server: $($server)"
    Write-Host " "
    Write-Host "Current Group Members: $($serverGroupMembers)"
    Write-Host " "
    Write-Host "Adding group $activeDirectoryGroup to $serverGroup"
    Write-Host " "
    
    # Add the Active Directory group to the local group on the server
    Invoke-Command -ComputerName $server -ScriptBlock {
        try{
            Add-LocalGroupMember -Group $using:serverGroup -Member $using:activeDirectoryGroup -ErrorAction stop
        } catch {
            # If the Active Directory group is already a member of the local group, ignore the error and continue
            if([string]$_.Exception.ErrorCategory -contains "ResourceExists"){
                Write-Host $_.Exception
                continue
            } else {
                Write-Host $_.Exception
                continue
            }
        }
    }
    
    # Get the updated group list
    $newserverGroup = Invoke-Command -ComputerName $server -ScriptBlock {Get-LocalGroupMember -Group $using:serverGroup}

    # Display the server name and the groups it is a member of
    if($newserverGroup.name -contains "SFI\$activeDirectoryGroup"){
        Write-Host " "
        Write-Host "Process Completed Successfully!"
        Write-Host " "
        Write-Host " "
        Write-Host "Server: $($server)"
        Write-Host "Groups: $($newserverGroup)"
        Write-Host " "
    } else {
        Write-Host "Process Failed
