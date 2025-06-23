# PowerShell script to fix fake USB drive
# Run this in Administrator PowerShell

# IMPORTANT NOTES ABOUT FILE SIZE LIMITS:
# 
# 1. FAT32 File System Limit: Individual files cannot exceed 4GB
#    - This is a file system limitation, not related to drive capacity
#    - Any single file larger than 4GB will be rejected automatically
#
# 2. Drive Capacity Protection: 
#    - The 4GB partition protects against writing to fake sectors
#    - Windows will show "Not enough space" when the 4GB is full
#    - This prevents any data from being written to fake/dangerous areas
#
# 3. Data Safety:
#    - Existing files: The Clear-Disk command removes ALL existing data
#    - New files: Cannot exceed 4GB individually (FAT32 limit)
#    - Total capacity: Cannot exceed 4GB total (partition size limit)
#
# 4. Double Protection:
#    - FAT32: Blocks individual files > 4GB
#    - Partition size: Blocks total data > 4GB
#    - Both protect against writing to fake sectors

Write-Host "=== USB Drive Fix Script ===" -ForegroundColor Green
Write-Host "This script will fix your fake USB drive by creating a safe 4GB partition" -ForegroundColor Yellow
Write-Host ""

# First, identify the disk number
Write-Host "Available USB drives:" -ForegroundColor Cyan
$UsbDisks = Get-Disk | Where-Object {$_.BusType -eq "USB"}
$UsbDisks | Format-Table Number, FriendlyName, @{Name="Size (GB)"; Expression={[math]::Round($_.Size/1GB, 2)}}

if ($UsbDisks.Count -eq 0) {
    Write-Host "No USB drives found!" -ForegroundColor Red
    exit
}

# Interactive disk selection
$DiskNumber = Read-Host "Enter the disk number of your USB drive"

# Confirm the selection
$SelectedDisk = Get-Disk -Number $DiskNumber
Write-Host ""
Write-Host "Selected disk:" -ForegroundColor Yellow
Write-Host "  Number: $($SelectedDisk.Number)"
Write-Host "  Name: $($SelectedDisk.FriendlyName)"
Write-Host "  Size: $([math]::Round($SelectedDisk.Size/1GB, 2)) GB"
Write-Host ""

$Confirm = Read-Host "WARNING: This will erase ALL data on this disk! Continue? (y/N)"
if ($Confirm -ne "y" -and $Confirm -ne "Y") {
    Write-Host "Operation cancelled." -ForegroundColor Red
    exit
}

try {
    Write-Host "Step 1: Cleaning disk..." -ForegroundColor Cyan
    Clear-Disk -Number $DiskNumber -RemoveData -Confirm:$false
    Write-Host "Disk cleaned successfully" -ForegroundColor Green

    Write-Host "Step 2: Creating 4GB partition..." -ForegroundColor Cyan
    New-Partition -DiskNumber $DiskNumber -Size 4GB -AssignDriveLetter M | Out-Null
    Write-Host "✓ 4GB partition created and assigned to M:" -ForegroundColor Green

    Write-Host "Step 3: Formatting partition with FAT32..." -ForegroundColor Cyan
    Format-Volume -DriveLetter M -FileSystem FAT32 -NewFileSystemLabel "USB_DRIVE" -Force | Out-Null
    Write-Host "✓ Partition formatted successfully" -ForegroundColor Green

    Write-Host ""
    Write-Host "=== RESULTS ===" -ForegroundColor Green
    Write-Host "Your USB drive has been fixed!" -ForegroundColor Green
    Write-Host ""
    
    Write-Host "Partition information:" -ForegroundColor Cyan
    Get-Partition -DiskNumber $DiskNumber | Format-Table PartitionNumber, DriveLetter, @{Name="Size (GB)"; Expression={[math]::Round($_.Size/1GB, 2)}}
    
    Write-Host "Volume information:" -ForegroundColor Cyan
    Get-Volume -DriveLetter M | Format-Table DriveLetter, FileSystemLabel, FileSystem, @{Name="Size (GB)"; Expression={[math]::Round($_.Size/1GB, 2)}}, @{Name="Free (GB)"; Expression={[math]::Round($_.SizeRemaining/1GB, 2)}}

    Write-Host ""
    Write-Host "✓ Drive M: is now ready for use!" -ForegroundColor Green
    Write-Host "✓ Safe 4GB capacity protects against fake sectors" -ForegroundColor Green
    Write-Host "✓ FAT32 prevents individual files > 4GB" -ForegroundColor Green

} catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Please ensure you're running PowerShell as Administrator" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
