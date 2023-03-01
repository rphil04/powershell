[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$ActiveDirectoryGroup,

    [Parameter(Mandatory = $true)]
    [string]$ServerGroup,

    [Parameter(Mandatory = $true)]
    [string]$ServerSearchPattern
)

#Import ActiveDirectory module
Import-Module ActiveDirectory

#Get the list of servers that match the search pattern
$servers = Get-ADComputer -Filter "Name -like '*$ServerSearchPattern*'" | select -ExpandProperty Name

#Prompt user to confirm changes
Write-Verbose "Servers to update:"
Write-Verbose "$servers"
$confirmation = Read-Host "Update membership on the following servers? [y/n]"
if ($confirmation -ne 'y') {
    Write-Verbose "Operation not confirmed, exiting"
    return
}

foreach ($server in $servers) {
    if(!(Test-Connection $server -Count 1 -Quiet)){
        Write-Host "$($server): Offline"
        continue
    }

    #Get the list of members currently in the local group
    $serverGroupMembers = Invoke-Command -ComputerName $server -ScriptBlock {Get-LocalGroupMember -Group $using:ServerGroup}

    if($serverGroupMembers.name -contains "SFI\$ActiveDirectoryGroup"){
        Write-Host "$($server): $ActiveDirectoryGroup is already a member of $ServerGroup"
        continue
    }

    #Get current list of group members
    Write-Verbose "Server: $($server)"
    Write-Verbose " "
    Write-Verbose "Current Group Members: $($serverGroupMembers)"
    Write-Verbose " "
    Write-Verbose "Adding group $ActiveDirectoryGroup to $ServerGroup"
    Write-Verbose " "

    #Add the AD group to the local server group on the current server
    Invoke-Command -ComputerName $server -ScriptBlock {
        try{
            Add-LocalGroupMember -Group $using:ServerGroup -Member $using:ActiveDirectoryGroup -ErrorAction Stop
        } catch {
            Write-Error $_.Exception
        }
    }

    #Get the updated group list
    $newserverGroup = Invoke-Command -ComputerName $server -ScriptBlock {Get-LocalGroupMember -Group $using:ServerGroup}

    #Print the server name and the groups it is a member of
    if($newserverGroup.name -contains "SFI\$ActiveDirectoryGroup"){
        Write-Verbose " "
        Write-Verbose "Process Completed Successfully!"
        Write-Verbose " "
        Write-Verbose "Server: $($server)"
        Write-Verbose
