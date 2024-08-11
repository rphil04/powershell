<#
===================================================
Network Device Scanner
===================================================
Author: Noytou
Date: 2024-10-06
Version: 1.1

Description:
------------
This PowerShell script scans the internal network to identify connected devices,
including their IP addresses, MAC addresses, and hostnames (if available).
The script compares the current scan results with the previous scan to
identify new or removed devices. The results are stored in a specified
directory for future analysis.

Usage:
------
- Customize the IP range according to your network configuration.
- Run the script with appropriate permissions.
- View the scan results in the C:\scripts\scans directory.

IP Range:
---------
- The IP range should be set according to your network.
  Example for 192.168.0.1 router: "192.168.0.1/24"

Output:
-------
- The results are saved to C:\scripts\scans\previous_scan.json.

===================================================
#>

# Directory and file to store previous scan results
$scanDirectory = "C:\scripts\scans"
$previousScanFile = Join-Path $scanDirectory "previous_scan.json"

# Ensure the scan directory exists
if (-not (Test-Path $scanDirectory)) {
    New-Item -Path $scanDirectory -ItemType Directory | Out-Null
}

function Scan-Network {
    param (
        [string]$ipRange
    )
    
    # Run ARP scan to get MAC addresses and IP addresses
    $arpResults = arp -a | ForEach-Object {
        $line = $_
        if ($line -match "^(\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3})\s+([a-f0-9:]+)\s+\w+") {
            $ip = $matches[1]
            $mac = $matches[2]
            $hostname = (Resolve-DnsName -Name $ip -ErrorAction SilentlyContinue).NameHost
            if (-not $hostname) {
                $hostname = "Unknown"
            }
            [PSCustomObject]@{
                IP       = $ip
                MAC      = $mac
                Hostname = $hostname
            }
        }
    }
    
    return $arpResults
}

function Load-PreviousScan {
    if (Test-Path $previousScanFile) {
        return Get-Content $previousScanFile | ConvertFrom-Json
    }
    return @()
}

function Save-CurrentScan {
    param (
        [array]$currentScan
    )
    
    $currentScan | ConvertTo-Json | Set-Content -Path $previousScanFile
}

function Compare-Scans {
    param (
        [array]$previousScan,
        [array]$currentScan
    )
    
    $previousIPs = $previousScan | ForEach-Object { $_.IP }
    $currentIPs = $currentScan | ForEach-Object { $_.IP }
    
    $newDevices = $currentScan | Where-Object { $_.IP -notin $previousIPs }
    $removedDevices = $previousScan | Where-Object { $_.IP -notin $currentIPs }
    
    return @{
        NewDevices     = $newDevices
        RemovedDevices = $removedDevices
    }
}

function Display-Devices {
    param (
        [array]$devices,
        [string]$label
    )
    
    Write-Host -ForegroundColor Cyan "`n$label"
    foreach ($device in $devices) {
        Write-Host "IP: $($device.IP), MAC: $($device.MAC), Hostname: $($device.Hostname)"
    }
}

# Main script execution
$ipRange = "192.168.0.1/24"

Write-Host "Scanning network..."
$currentScan = Scan-Network -ipRange $ipRange

$previousScan = Load-PreviousScan
$scanComparison = Compare-Scans -previousScan $previousScan -currentScan $currentScan

Display-Devices -devices $currentScan -label "Current Devices"
Display-Devices -devices $scanComparison.NewDevices -label "New Devices"
Display-Devices -devices $scanComparison.RemovedDevices -label "Removed Devices"

Save-CurrentScan -currentScan $currentScan
Write-Host -ForegroundColor Green "`nScan completed and saved to $previousScanFile."
