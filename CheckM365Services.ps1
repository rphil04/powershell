# Define URLs for Microsoft services
$m365Url = "https://status.office.com/status"
$oneDriveUrl = "https://status.office.com/onedrive"

# Define function to check status of a service
function Check-ServiceStatus {
    param(
        [string]$url
    )
    try {
        $request = [System.Net.WebRequest]::Create($url)
        $response = $request.GetResponse()
        return $response.StatusCode -lt 400
    } catch {
        return $false
    }
}

# Check status of Microsoft 365 services
$m365Status = Check-ServiceStatus -url $m365Url

# Check status of OneDrive services
$oneDriveStatus = Check-ServiceStatus -url $oneDriveUrl

# Print status of each service
Write-Host "Microsoft 365 services are" $(if ($m365Status) { "up" } else { "down" })
Write-Host "OneDrive services are" $(if ($oneDriveStatus) { "up" } else { "down" })
