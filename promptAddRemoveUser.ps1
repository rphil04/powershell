<#
.SYNOPSIS
Script to view, add, or remove Active Directory groups from local security groups on a specified server.

.DESCRIPTION
Prompts user to select a server and local group to view members. Then allows user to either add or
remove AD groups from the selected local group. Supports multiple group names separated by commas.

.PARAMETER ServerName
The name of the server to manage group membership on.

.PARAMETER GroupName
The local group name ("Administrators" or "Remote Desktop Users").
#>

# Clear the screen
Clear-Host

# Step 1: Prompt for server name
Write-Host "`nPlease enter the following information:"
$serverName = Read-Host "Enter server name"

# Step 2: Prompt for group to view
Write-Host "`nSelect a local security group to view members:"
Write-Host "1. Administrators"
Write-Host "2. Remote Desktop Users"
$groupSelection = Read-Host "Enter the number for the group (1 or 2)"

# Step 3: Map selection
switch ($groupSelection) {
   "1" { $groupName = "Administrators" }
   "2" { $groupName = "Remote Desktop Users" }
   Default {
       Write-Host "Invalid selection. Please enter 1 or 2."
       exit
   }
}

# Step 4: Display members of selected group
Write-Host "`nGathering information, please wait...`n"
$group = [ADSI]("WinNT://$serverName/$groupName,group")
$groupMembers = $group.Members() | ForEach-Object {
   $_.GetType().InvokeMember("Name", 'GetProperty', $null, $_, $null)
}

if ($groupMembers) {
   Write-Host "The members of the $groupName group on $serverName are:"
   $groupMembers
} else {
   Write-Host "The $groupName group on $serverName has no members."
}

# Step 5: Prompt for action
$action = Read-Host "`nDo you want to add a user or remove a user? (add/remove)"
if ($action -ne "add" -and $action -ne "remove") {
   Write-Host "Invalid action. Please enter 'add' or 'remove'."
   exit
}

# Step 6: Prompt for group to modify (Administrators or RDP)
Write-Host "`nSelect a local security group to $action Active Directory group(s):"
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

# Get reference to the local group
$localGroupObj = [ADSI]("WinNT://$serverName/$localGroup,group")

# Step 7: Perform add or remove
if ($action -eq "add") {
   $adGroupInput = Read-Host "`nEnter the name(s) of the Active Directory group(s) to add (comma-separated)"
   $adGroups = $adGroupInput -split "," | ForEach-Object { $_.Trim() }

   foreach ($adGroup in $adGroups) {
       try {
           $localGroupObj.Add("WinNT://$adGroup,group")
           Write-Host "$adGroup successfully added to $localGroup."
       } catch {
           Write-Host "Failed to add $adGroup to $localGroup. Error: $_"
       }
   }
} elseif ($action -eq "remove") {
   $adGroupInput = Read-Host "`nEnter the name(s) of the Active Directory group(s) to remove (comma-separated)"
   $adGroups = $adGroupInput -split "," | ForEach-Object { $_.Trim() }

   foreach ($adGroup in $adGroups) {
       try {
           $localGroupObj.Remove("WinNT://$adGroup,group")
           Write-Host "$adGroup successfully removed from $localGroup."
       } catch {
           Write-Host "Failed to remove $adGroup from $localGroup. Error: $_"
       }
   }
}

# Step 8: Display updated members
$groupMembers = $localGroupObj.Members() | ForEach-Object {
   $_.GetType().InvokeMember("Name", 'GetProperty', $null, $_, $null)
}

Write-Host "`nThe members of the $localGroup group on $serverName are now:"
$groupMembers