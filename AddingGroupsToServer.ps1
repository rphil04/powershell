
Import-Module ActiveDirectory

#Prompt user to list the AD group
cls
$activeDirectoryGroup = Read-Host "Enter the Active Directory group to add to the server"

#Prompt user to list the local group
$serverGroup = Read-Host "Enter the local group that the Active Directory group needs to be added to"

#Prompt user for server search criteria
$serverSearch = Read-Host "Enter the server pattern to search for/update"

#Get the list of servers that match the pattern "*ver0"
#$servers = Get-ADComputer -Filter {Name -like "*ver0" -or Name -like "server3"} | select -Property Name

#Get the list of servers that match the pattern "*ver0"
$servers = Get-ADComputer -Filter "Name -like '*$serverSearch*'" | select -Property Name

#Have user confirm changes
write-host "Servers targets:"
write-host "$($servers.name)"
$confirmation = Read-Host "Update membership on the following servers? [y/n]"
    if ($confirmation -ne 'y') {
        write-host "Operation not confirmed, exiting"
        sleep -Seconds 5
        exit
    }
    
foreach ($server in $servers.name) {
    if(!(test-connection $server -Count 1 -Quiet)){
        write-host "$($server): Offline"
        continue
    }

    #Get the list of members currently in the local group
    $serverGroupMembers = invoke-command -computername $server -scriptblock {Get-LocalGroupMember -Group $using:serverGroup}

    if($serverGroupMembers.name -contains "SFI\$activeDirectoryGroup"){
        write-host "$($server): $activeDirectoryGroup is already a member of $serverGroup"
        continue
    }

    #Get current list of group members
    Write-Host "Server: $($server)"
    Write-Host " "
    Write-Host "Current Group Members: $($serverGroupMembers)"
    Write-Host " "
    Write-Host "Adding group $activeDirectoryGroup to $serverGroup"
    Write-Host " "
    
    #Add the AD group to the local server group on the current server
      invoke-command -computername $server -scriptblock {
        try{

        Add-LocalGroupMember -Group $using:serverGroup -Member $using:activeDirectoryGroup -ErrorAction stop
        } catch {
            if([string]$_.Exception.ErrorCategory -contains "ResourceExists"){
                write-host $_.Exception
                continue
            } else {
                write-host $_.Exception
                continue
            }
        }
    }
    
    #Get the updated group list
    $newserverGroup = invoke-command -computername $server -scriptblock {Get-LocalGroupMember -Group $using:serverGroup}
    #Print the server name and the groups it is a member of
    if($newserverGroup.name -contains "SFI\$activeDirectoryGroup"){
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
