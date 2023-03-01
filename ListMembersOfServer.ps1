Import-Module ActiveDirectory

# Prompt user to enter the server name
$serverName = Read-Host "Enter the server name"

# Get the list of members in the Administrators group
$adminMembers = Invoke-Command -ComputerName $serverName -ScriptBlock {Get-LocalGroupMember -Group "Administrators"} | Select-Object -ExpandProperty Name

# Get the list of members in the Remote Desktop Users group
$rdpMembers = Invoke-Command -ComputerName $serverName -ScriptBlock {Get-LocalGroupMember -Group "Remote Desktop Users"} | Select-Object -ExpandProperty Name

# Output the lists of members
Write-Host "Administrators group members:"
Write-Host $adminMembers
Write-Host "Remote Desktop Users group members:"
Write-Host $rdpMembers
