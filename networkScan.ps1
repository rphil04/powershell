# Define file paths
$previousScanFile = "C:\scripts\scans\previous_scan.txt"
$currentScanFile = "C:\scripts\scans\current_scan.txt"
$newDevicesFile = "C:\scripts\scans\new_devices.txt"

# Perform network scan
function Get-NetworkDevices {
    $subnet = "192.168.0"  # Replace with your subnet base
    $ipRange = 1..254
    $devices = @()

    $ipRange | ForEach-Object -Parallel {
        param ($ipRange, $subnet, $devices)

        $ip = "$subnet.$_"
        $result = [PSCustomObject]@{
            IPAddress = $ip
            MACAddress = "N/A"
            Hostname = "N/A"
        }

        if (Test-Connection -ComputerName $ip -Count 1 -Quiet) {
            $result.Hostname = "N/A"
            try {
                $result.Hostname = [System.Net.Dns]::GetHostEntry($ip).HostName
            } catch {
                # Handle DNS resolution exception
            }

            $result.MACAddress = $null
            try {
                $result.MACAddress = (Get-NetNeighbor -IPAddress $ip).LinkLayerAddress
            } catch {
                # Handle WMI query exception
            }
        }

        $devices += $result
    } -ThrottleLimit 10 -ArgumentList $ipRange, $subnet, $devices

    $devices
}

# Save current scan
function Save-Scan {
    param (
        [string]$filePath,
        [array]$devices
    )
    Write-Host "Saving scan to $filePath..."
    $devices | Export-Csv -Path $filePath -NoTypeInformation
}

# Compare scans
function Compare-Scans {
    param (
        [string]$previousFilePath,
        [string]$currentFilePath,
        [string]$newDevicesFilePath
    )
    if (Test-Path $previousFilePath) {
        Write-Host "Loading previous scan from $previousFilePath..."
        $previousScan = Import-Csv -Path $previousFilePath
    } else {
        Write-Host "No previous scan found, creating new..."
        $previousScan = @()
    }
    Write-Host "Loading current scan from $currentFilePath..."
    $currentScan = Import-Csv -Path $currentFilePath

    $newDevices = $currentScan | Where-Object {
        $previousScan -notcontains $_
    }
    Write-Host "Saving new devices to $newDevicesFilePath..."
    $newDevices | Export-Csv -Path $newDevicesFilePath -NoTypeInformation
}

# Main execution
Write-Host "Starting network scan..."
$currentDevices = Get-NetworkDevices
Save-Scan -filePath $currentScanFile -devices $currentDevices
Compare-Scans -previousFilePath $previousScanFile -currentFilePath $currentScanFile -newDevicesFilePath $newDevicesFile

# Display results
Write-Host "Current devices:"
$currentDevices | Format-Table -AutoSize
Write-Output "New devices since last scan:"
Get-Content $newDevicesFile
