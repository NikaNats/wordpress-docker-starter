# WordPress Production Backup Script for Windows
# Creates full backup of WordPress files and database

param(
    [string]$BackupDir = "./backups",
    [string]$DockerComposeFile = "docker-compose.prod.yml",
    [int]$RetentionDays = 30
)

$ErrorActionPreference = "Stop"

$Date = Get-Date -Format "yyyyMMdd_HHmmss"
$BackupName = "wordpress_backup_$Date"

Write-Host "WordPress Production Backup - Windows" -ForegroundColor Green
Write-Host "======================================"

# Create backup directory
if (-not (Test-Path $BackupDir)) {
    New-Item -ItemType Directory -Path $BackupDir -Force | Out-Null
    Write-Host "Created backup directory: $BackupDir" -ForegroundColor Green
}

$TempDir = "$BackupDir\temp_$BackupName"
New-Item -ItemType Directory -Path $TempDir -Force | Out-Null

try {
    Write-Host "Starting backup: $BackupName" -ForegroundColor Yellow
    
    # Backup WordPress files
    Write-Host "Backing up WordPress files..." -ForegroundColor Yellow
    $wpContentSource = ".\wp-content"
    $wpContentBackup = "$TempDir\wp-content.zip"
    
    if (Test-Path $wpContentSource) {
        Compress-Archive -Path $wpContentSource -DestinationPath $wpContentBackup -Force
        Write-Host "WordPress files backed up: $wpContentBackup" -ForegroundColor Green
    } else {
        Write-Host "Warning: wp-content directory not found" -ForegroundColor Yellow
    }
    
    # Backup database
    Write-Host "Backing up database..." -ForegroundColor Yellow
    $dbBackup = "$TempDir\database.sql"
    
    # Get database password from secrets
    $dbPassword = Get-Content ".\secrets\db_root_password.txt" -Raw
    $dbName = "wordpress_prod"
    
    # Create mysqldump command
    $dumpCommand = "docker-compose -f $DockerComposeFile exec -T db mysqldump -u root -p'$dbPassword' --single-transaction --routines --triggers $dbName"
    
    # Execute database dump
    try {
        Invoke-Expression "$dumpCommand > `"$dbBackup`"" 
        Write-Host "Database backed up: $dbBackup" -ForegroundColor Green
    } catch {
        Write-Host "Error backing up database: $($_.Exception.Message)" -ForegroundColor Red
        # Continue with file backup even if DB backup fails
    }
    
    # Create final backup archive
    Write-Host "Creating backup archive..." -ForegroundColor Yellow
    $finalBackup = "$BackupDir\$BackupName.zip"
    Compress-Archive -Path "$TempDir\*" -DestinationPath $finalBackup -Force
    
    # Cleanup temp directory
    Remove-Item -Path $TempDir -Recurse -Force
    
    Write-Host "Backup completed successfully: $finalBackup" -ForegroundColor Green
    
    # Cleanup old backups
    Write-Host "Cleaning up backups older than $RetentionDays days..." -ForegroundColor Yellow
    $cutoffDate = (Get-Date).AddDays(-$RetentionDays)
    Get-ChildItem -Path $BackupDir -Filter "wordpress_backup_*.zip" | Where-Object { $_.CreationTime -lt $cutoffDate } | ForEach-Object {
        Remove-Item $_.FullName -Force
        Write-Host "Removed old backup: $($_.Name)" -ForegroundColor Yellow
    }
    
    # Display backup info
    $backupSize = (Get-Item $finalBackup).Length / 1MB
    Write-Host "`nBackup Summary:" -ForegroundColor Green
    Write-Host "- Backup file: $finalBackup"
    Write-Host "- Size: $([math]::Round($backupSize, 2)) MB"
    Write-Host "- Created: $(Get-Date)"
    
} catch {
    Write-Host "Backup failed: $($_.Exception.Message)" -ForegroundColor Red
    
    # Cleanup on failure
    if (Test-Path $TempDir) {
        Remove-Item -Path $TempDir -Recurse -Force
    }
    
    exit 1
}

Write-Host "`nBackup process completed successfully!" -ForegroundColor Green
