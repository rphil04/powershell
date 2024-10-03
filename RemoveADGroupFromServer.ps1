<#
.SYNOPSIS
This script retrieves the members of a specified local security group on a specified server and allows the user to remove a security group from the server.
.DESCRIPTION
This script prompts the user to enter a server name and select a local security group 
(1 for "Administrators" or 2 for "Remote Desktop Users"), and then retrieves the members of the specified group on the specified server using the WinNT provider.
It also allows the user to remove an existing security group from the specified local security group on the server.
.PARAMETER ServerName
Specifies the name of the server to retrieve group members from.
.PARAMETER GroupName
Specifies the name of the local security group to retrieve members from.
#>

# Clear the screen
Clear-Host

# Prompt the user for the server name
Write-Host "Please enter the following information:"
$serverName = Read-Host "Enter server name"

# Display group options and get selection
Write-Host "Select a local security group: "
Write-Host "1. Administrators"
Write-Host "2. Remote Desktop Users"
$groupSelection = Read-Host "Enter the number for the group (1 or 2)"

# Map the selection to a group name
switch ($groupSelection) {
    "1" { $groupName = "Administrators" }
    "2" { $groupName = "Remote Desktop Users" }
    Default {
        Write-Host "Invalid selection. Please enter 1 or 2."
        exit
    }
}

# Retrieve the group members
Write-Host " "
Write-Host "Gathering information, please wait..."
Write-Host " "
$group = [ADSI]("WinNT://$serverName/$groupName,group")
$groupMembers = $group.Members() | ForEach-Object {
    $_.GetType().InvokeMember("Name", 'GetProperty', $null, $_, $null)
}

# Display the results
if ($groupMembers) {
    Write-Host " "
    Write-Host "The members of the $groupName group on $serverName are:"
    $groupMembers
} else {
    Write-Host "The $groupName group on $serverName has no members."
}

# Prompt the user to remove a security group from the server
$removeGroup = Read-Host "Do you want to remove an existing security group from the server? (Y/N)"
if ($removeGroup -eq "Y") {
    $adGroup = Read-Host "Enter the name of the Active Directory group to remove"

    # Prompt for group name with selection
    Write-Host "Select a local security group to remove the Active Directory group from: "
    Write-Host "1. Administrators"
    Write-Host "2. Remote Desktop Users"
    $localGroupSelection = Read-Host "Enter the number for the group (1 or 2)"

    switch ($localGroupSelection) {
        "1" { $localGroup = "Administrators" }
        "2" { $localGroup = "Remote Desktop Users" }
        Default {
            Write-Host "Invalid selection. Please enter 1 or 2."
            exit
        }
    }

    # Remove the Active Directory group from the local security group
    $localGroupObj = [ADSI]("WinNT://$serverName/$localGroup,group")
    try {
        $localGroupObj.Remove("WinNT://$adGroup,group")
        Write-Host "$adGroup has been removed from the $localGroup group on $serverName."
    } catch {
        Write-Host "Error: Could not remove $adGroup from $localGroup on $serverName."
    }

    # Retrieve the updated group members
    $groupMembers = $localGroupObj.Members() | ForEach-Object {
        $_.GetType().InvokeMember("Name", 'GetProperty', $null, $_, $null)
    }

    # Display the updated group members
    Write-Host " "
    Write-Host "The members of the $localGroup group on $serverName are now:"
    $groupMembers
}