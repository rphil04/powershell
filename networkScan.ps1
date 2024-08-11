# Define file paths
$previousScanFile = "C:\scripts\scans\previous_scan.txt"
$currentScanFile = "C:\scripts\scans\current_scan.txt"
$newDevicesFile = "C:\scripts\scans\new_devices.txt"

# Perform network scan
function Get-NetworkDevices {
    $devices = @()
    $subnet = "192.168.1"  # Replace with your subnet
    1..254 | ForEach-Object {
        $ip = "$subnet.$_"
        if (Test-Connection -ComputerName $ip -Count 1 -Quiet) {
            $hostname = "N/A"
            try {
                $hostname = [System.Net.Dns]::GetHostEntry($ip).HostName
            } catch {
                # Handle exception (e.g., log the error or continue)
            }
            $mac = (Get-WmiObject -Query "SELECT * FROM Win32_NetworkAdapterConfiguration WHERE IPEnabled = 'TRUE'" |
                    Where-Object { $_.IPAddress -contains $ip } |
                    ForEach-Object { $_.MACAddress } |
                    Out-String).Trim()
            $devices += [PSCustomObject]@{
                IPAddress = $ip
                MACAddress = $mac
                Hostname = $hostname
            }
        }
    }
    $devices
}

# Save current scan
function Save-Scan {
    param (
        [string]$filePath,
        [array]$devices
    )
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
        $previousScan = Import-Csv -Path $previousFilePath
    } else {
        $previousScan = @()
    }
    $currentScan = Import-Csv -Path $currentFilePath

    $newDevices = $currentScan | Where-Object {
        $previousScan -notcontains $_
    }
    $newDevices | Export-Csv -Path $newDevicesFilePath -NoTypeInformation
}

# Main execution
$currentDevices = Get-NetworkDevices
Save-Scan -filePath $currentScanFile -devices $currentDevices
Compare-Scans -previousFilePath $previousScanFile -currentFilePath $currentScanFile -newDevicesFilePath $newDevicesFile

# Display results
$currentDevices | Format-Table -AutoSize
Write-Output "New devices since last scan:"
Get-Content $newDevicesFile
