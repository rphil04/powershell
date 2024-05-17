# Function to add user to groups
function Add-UserToGroups {
   param (
       [string]$Username,
       [string[]]$Groups
   )
   foreach ($Group in $Groups) {
       try {
           Add-ADGroupMember -Identity $Group -Members $Username
           Write-Host "Added $Username to $Group" -ForegroundColor Green
       } catch {
           $errorMessage = $_.Exception.Message
           Write-Host "Failed to add $Username to $Group $errorMessage" -ForegroundColor Red
       }
   }
}
# Get the username
$Username = Read-Host "Enter the username"
# Define training and groups mapping
$trainingGroupsMap = @{
   "Active Directory (Workday)" = @("ADAudit_Admin", "ADAudit_Operator", "ADFS_Admins", "EUS_AD_Admin", "EUS_Support_HD_OU", "EUS-AD")
   "Enterprise Print (Workday)" = @("SFIPrintOperators")
   "Enterprise Server (Workday)" = @("oid_unix_admins", "oid_unix_syncusers", "SFI_PltSvr_Restart", "unix_rl_ists-ns", "unix_srv_ists-ns", "SFI_DC_AllowLogon", "SFI_DC_Restart")
   "Network (Workday)" = @("SFI_DNS_Viewers")
   "Enterprise Workstation (Meeting)" = @("AllWkstn_LocalAdmTtl", "GPO_Exceptions_ProductionComputers", "Intune_SFI_Support_Admins", "VNC_Total_PROD", "ISCS-HW", "WebCenterAdmins")
   "Exchange (Meeting)" = @("EUS-Exchange")
   "File Server (Workday)" = @("FileServerAdm_Ttl")
   "VMWare (Workday)" = @("VICAccess_Avalanche", "VICAccess_FVControls", "VICAccess_IS-Sec", "VICAccess_ISTS-NS")
   "SCCM Training (Meeting)" = @("SFI_SCCM_Collection_Admins", "SFI_SCCM_ReportViewers")
}
# Loop through each training
foreach ($training in $trainingGroupsMap.Keys) {
   $response = Read-Host "Has $training training been completed? (yes/no)"
   if ($response -eq 'yes') {
       Add-UserToGroups -Username $Username -Groups $trainingGroupsMap[$training]
   }
}
# Prompt for SiteManagerTotal access
$siteManagerResponse = Read-Host "Does the user need SiteManagerTotal access? (yes/no)"
if ($siteManagerResponse -eq 'yes') {
   try {
       Add-ADGroupMember -Identity "SiteManagerTotal" -Members $Username
       Write-Host "Added $Username to SiteManagerTotal" -ForegroundColor Green
   } catch {
       Write-Host "Failed to add $Username to SiteManagerTotal: $_" -ForegroundColor Red
   }
}
# Reminder to manually add the user to specific groups
Write-Host "Reminder: Please manually add the user to PwdMgmtXXX, SiteManagerXXX, SiteManagerTotal, AllWkstn_LocalAdmXXX, SecurePrintAccountMgrs-XXX, VNC_XXX_PROD, VICAccess_ITPS-XXXXX groups." -ForegroundColor Yellow