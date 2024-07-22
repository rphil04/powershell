<#
.SYNOPSIS
    Script to monitor USB drive insertions, scan for malware, create a CSV of file hashes, and safely eject the USB drive.

.DESCRIPTION
    This script performs the following tasks:
    1. Detects when a new USB drive is connected.
    2. Uses Windows Defender to scan the drive for malicious software.
    3. Creates a CSV file and saves it to C:\usb-scans. The CSV records the file names and cryptohash for all files on the USB drive and flags 
       any potentially harmful files detected by Windows Defender.
    4. Displays the CSV content in the PowerShell prompt in a readable format.
    5. Safely ejects the USB drive once the process completes.

.NOTES
    Run this script with administrative privileges.
    To setup a scheduled task perform the following
       1. Open Task Scheduler.
       2. Click on Create Task.
       3. In the General tab, name your task (e.g., "USB Drive Detection").
       4. In the Triggers tab, click New and:
       5. Begin the task: On an event
       6. Log: System
       7. Source: Kernel-PnP
       8. Event ID: 20001
       9. In the Actions tab, click New and:
       10. Action: Start a program
       11. Program/script: powershell.exe
       12. Add arguments: -NoProfile -ExecutionPolicy Bypass -File "C:\Path\To\Your\Script.ps1"
       13. In the Conditions tab, uncheck Start the task only if the computer is on AC power.
       14. Click OK to create the task.

.VERSION
    1.0

#>

# Define the path for the CSV files
$csvPath = "C:\usb-scans"

# Function to calculate the SHA256 hash of a file
function Get-FileHashSHA256 {
    param (
        [string]$filePath
    )
    try {
        $hash = Get-FileHash -Path $filePath -Algorithm SHA256
        return $hash.Hash
    } catch {
        Write-Error "Error calculating hash for $filePath: $_"
        return $null
    }
}

# Function to scan the USB drive with Windows Defender
function Scan-UsbDrive {
    param (
        [string]$driveLetter
    )
    try {
        Write-Output "Scanning drive $driveLetter with Windows Defender..."
        Start-MpScan -ScanType CustomScan -ScanPath "$driveLetter"
    } catch {
        Write-Error "Error scanning drive $driveLetter: $_"
    }
}

# Function to create CSV with file names and cryptohashes
function Create-CsvWithHashes {
    param (
        [string]$driveLetter,
        [string]$csvPath
    )
    try {
        $csvFileName = (Get-Date).ToString("yyyy-MMdd-HHmm") + ".csv"
        $csvFullPath = Join-Path -Path $csvPath -ChildPath $csvFileName
        $fileList = Get-ChildItem -Path "$driveLetter\*" -Recurse -File

        $csvContent = @()
        foreach ($file in $fileList) {
            $hash = Get-FileHashSHA256 -filePath $file.FullName
            if ($hash) {
                $csvContent += [PSCustomObject]@{
                    FileName = $file.FullName
                    FileHash = $hash
                    IsPotentiallyHarmful = $false
                }
            }
        }

        $csvContent | Export-Csv -Path $csvFullPath -NoTypeInformation
        Write-Output "CSV created at $csvFullPath"
        return $csvFullPath
    } catch {
        Write-Error "Error creating CSV for drive $driveLetter: $_"
        return $null
    }
}

# Function to check for threats found by Windows Defender
function Check-ForThreats {
    param (
        [string]$driveLetter,
        [string]$csvPath
    )
    try {
        $csvContent = Import-Csv -Path $csvPath
        $threats = Get-MpThreatDetection | Where-Object { $_.Resources -like "$driveLetter\*" }

        foreach ($threat in $threats) {
            $threatFilePath = $threat.Resources
            foreach ($csvRow in $csvContent) {
                if ($csvRow.FileName -eq $threatFilePath) {
                    $csvRow.IsPotentiallyHarmful = $true
                }
            }
        }

        $csvContent | Export-Csv -Path $csvPath -NoTypeInformation
        return $csvContent
    } catch {
        Write-Error "Error checking for threats on drive $driveLetter: $_"
        return $null
    }
}

# Function to display the CSV content in a readable format
function Display-CsvContent {
    param (
        [string]$csvPath
    )
    try {
        $csvContent = Import-Csv -Path $csvPath
        $csvContent | Format-Table -AutoSize
    } catch {
        Write-Error "Error displaying CSV content from $csvPath: $_"
    }
}

# Function to safely eject the USB drive
function Eject-UsbDrive {
    param (
        [string]$driveLetter
    )
    try {
        $drive = Get-Volume | Where-Object { $_.DriveLetter -eq $driveLetter }
        if ($drive) {
            $volumePath = "\\?\Volume{$($drive.DriveId)}"
            Write-Output "Ejecting drive $driveLetter..."
            (& "C:\Windows\System32\mountvol.exe" $volumePath /p) | Out-Null
            Write-Output "Drive $driveLetter ejected."
        } else {
            Write-Output "Drive $driveLetter not found for ejection."
        }
    } catch {
        Write-Error "Error ejecting drive $driveLetter: $_"
    }
}

# Main function to perform tasks for new USB connections
function Process-UsbDrive {
    param (
        [string]$driveLetter
    )
    try {
        Write-Output "New USB drive detected: $driveLetter"
        Scan-UsbDrive -driveLetter $driveLetter
        $csvPath = Create-CsvWithHashes -driveLetter $driveLetter -csvPath $csvPath
        if ($csvPath) {
            $updatedCsvContent = Check-ForThreats -driveLetter $driveLetter -csvPath $csvPath
            Display-CsvContent -csvPath $csvPath
            Eject-UsbDrive -driveLetter $driveLetter
        }
    } catch {
        Write-Error "Error processing drive $driveLetter: $_"
    }
}

# Create the directory for storing CSV files if it doesn't exist
if (-not (Test-Path -Path $csvPath)) {
    try {
        New-Item -ItemType Directory -Path $csvPath
        Write-Output "Created directory $csvPath"
    } catch {
        Write-Error "Error creating directory $csvPath: $_"
        exit
    }
}

# Detect the latest USB drive inserted
$latestUsbDrive = Get-Volume | Where-Object { $_.DriveType -eq 'Removable' } | Sort-Object -Property DriveLetter -Descending | Select-Object -First 1

if ($latestUsbDrive) {
    Process-UsbDrive -driveLetter $latestUsbDrive.DriveLetter
} else {
    Write-Output "No USB drive detected."
}
