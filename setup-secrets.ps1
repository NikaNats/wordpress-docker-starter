# PowerShell script to set up secrets for WordPress Docker Starter
# This script helps you securely generate and store passwords

$SecretsDir = "./secrets"

Write-Host "WordPress Docker Starter - Secrets Setup" -ForegroundColor Green
Write-Host "============================================="

# Create secrets directory if it doesn't exist
if (-not (Test-Path $SecretsDir)) {
    New-Item -ItemType Directory -Path $SecretsDir | Out-Null
    Write-Host "Created secrets directory" -ForegroundColor Green
}

# Function to generate secure password
function Generate-Password {
    param([int]$Length = 20)
    
    $chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789!@#$%^&*"
    $password = ""
    for ($i = 0; $i -lt $Length; $i++) {
        $password += $chars[(Get-Random -Maximum $chars.Length)]
    }
    return $password
}

# Function to set up a secret
function Setup-Secret {
    param(
        [string]$SecretName,
        [string]$Description
    )
    
    $secretFile = Join-Path $SecretsDir "$SecretName.txt"
    
    Write-Host ""
    Write-Host "Setting up: $Description" -ForegroundColor Yellow
    
    if (Test-Path $secretFile) {
        Write-Host "Secret file already exists: $secretFile" -ForegroundColor Yellow
        $overwrite = Read-Host "Do you want to overwrite it? (y/N)"
        if ($overwrite -notmatch "^[Yy]$") {
            Write-Host "Skipping $SecretName"
            return
        }
    }
    
    $password = Read-Host "Enter password (or press Enter to generate one)" -AsSecureString
    $plaintextPassword = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto([System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($password))
    
    if ([string]::IsNullOrEmpty($plaintextPassword)) {
        $plaintextPassword = Generate-Password -Length 20
        Write-Host "Generated secure password" -ForegroundColor Green
    }
    
    $plaintextPassword | Out-File -FilePath $secretFile -Encoding utf8 -NoNewline
    Write-Host "Saved: $secretFile" -ForegroundColor Green
}

# Set up each secret
Setup-Secret -SecretName "db_root_password" -Description "MySQL Root Password"
Setup-Secret -SecretName "db_password" -Description "WordPress Database Password"  
Setup-Secret -SecretName "wp_admin_password" -Description "WordPress Admin Password"

Write-Host ""
Write-Host "Secrets setup complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Review your .env file for non-sensitive configuration"
Write-Host "2. Run: docker-compose up -d"
Write-Host "3. Your WordPress site will be available at the configured URL"
Write-Host ""
Write-Host "SECURITY REMINDER:" -ForegroundColor Red
Write-Host "- The secrets/ directory is excluded from git"
Write-Host "- Keep these files secure and back them up separately"
Write-Host "- Never commit secret files to version control"
