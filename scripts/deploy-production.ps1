# WordPress Docker Production Deployment Script
# Automated production deployment with security checks

param(
    [string]$Domain = "",
    [string]$Email = "",
    [switch]$SkipChecks = $false
)

$ErrorActionPreference = "Stop"

Write-Host "WordPress Docker Production Deployment" -ForegroundColor Green
Write-Host "======================================"

# Pre-deployment security checks
if (-not $SkipChecks) {
    Write-Host "`nPerforming security checks..." -ForegroundColor Yellow
    
    # Check if secrets exist and are not default
    $secretsOk = $true
    
    $secretFiles = @("db_root_password.txt", "db_password.txt", "wp_admin_password.txt")
    foreach ($file in $secretFiles) {
        $secretPath = ".\secrets\$file"
        if (-not (Test-Path $secretPath)) {
            Write-Host "❌ Missing secret file: $file" -ForegroundColor Red
            $secretsOk = $false
        } else {
            $content = Get-Content $secretPath -Raw
            if ($content.Length -lt 20) {
                Write-Host "❌ Secret file too short (weak password): $file" -ForegroundColor Red
                $secretsOk = $false
            } else {
                Write-Host "✅ Secret file OK: $file" -ForegroundColor Green
            }
        }
    }
    
    # Check SSL certificates
    $sslFiles = @("cert.pem", "key.pem", "dhparam.pem")
    $sslOk = $true
    foreach ($file in $sslFiles) {
        $sslPath = ".\config\ssl\$file"
        if (-not (Test-Path $sslPath)) {
            Write-Host "❌ Missing SSL file: $file" -ForegroundColor Red
            $sslOk = $false
        } else {
            Write-Host "✅ SSL file OK: $file" -ForegroundColor Green
        }
    }
    
    # Check environment configuration
    if (Test-Path ".env") {
        $envContent = Get-Content ".env" -Raw
        if ($envContent -match "your-domain.com") {
            Write-Host "❌ Environment file contains placeholder domain" -ForegroundColor Red
            Write-Host "   Please update .env file with your actual domain" -ForegroundColor Yellow
            $secretsOk = $false
        } else {
            Write-Host "✅ Environment configuration updated" -ForegroundColor Green
        }
    }
    
    if (-not $secretsOk -or -not $sslOk) {
        Write-Host "`n❌ Pre-deployment checks failed!" -ForegroundColor Red
        Write-Host "Please fix the issues above before deploying to production." -ForegroundColor Yellow
        exit 1
    }
    
    Write-Host "`n✅ All security checks passed!" -ForegroundColor Green
}

# Prompt for domain and email if not provided
if ([string]::IsNullOrEmpty($Domain)) {
    $Domain = Read-Host "Enter your production domain (e.g., example.com)"
}

if ([string]::IsNullOrEmpty($Email)) {
    $Email = Read-Host "Enter your email for SSL certificates"
}

# Update environment file
Write-Host "`nUpdating environment configuration..." -ForegroundColor Yellow

if (Test-Path ".env") {
    $envContent = Get-Content ".env" -Raw
    $envContent = $envContent -replace "your-production-domain.com", $Domain
    $envContent = $envContent -replace "ssl-admin@your-production-domain.com", $Email
    $envContent = $envContent -replace "admin@your-production-domain.com", $Email
    $envContent | Set-Content ".env" -Encoding UTF8
    Write-Host "Environment file updated with domain: $Domain" -ForegroundColor Green
}

# Create backup before deployment
Write-Host "`nCreating pre-deployment backup..." -ForegroundColor Yellow
try {
    .\scripts\backup-windows.ps1
    Write-Host "Pre-deployment backup completed" -ForegroundColor Green
} catch {
    Write-Host "Warning: Backup failed, continuing with deployment..." -ForegroundColor Yellow
}

# Stop any running containers
Write-Host "`nStopping existing containers..." -ForegroundColor Yellow
docker-compose down 2>$null

# Deploy production environment
Write-Host "`nDeploying production environment..." -ForegroundColor Yellow
docker-compose -f docker-compose.prod.yml up -d

# Wait for containers to start
Write-Host "`nWaiting for containers to start..." -ForegroundColor Yellow
Start-Sleep -Seconds 30

# Check container status
Write-Host "`nContainer Status:" -ForegroundColor Yellow
docker-compose -f docker-compose.prod.yml ps

# Test connectivity
Write-Host "`nTesting connectivity..." -ForegroundColor Yellow
try {
    $response = Invoke-WebRequest -Uri "http://localhost" -TimeoutSec 10 -UseBasicParsing
    if ($response.StatusCode -eq 200) {
        Write-Host "✅ HTTP connectivity OK" -ForegroundColor Green
    }
} catch {
    Write-Host "❌ HTTP connectivity failed" -ForegroundColor Red
}

try {
    $response = Invoke-WebRequest -Uri "https://localhost" -TimeoutSec 10 -UseBasicParsing -SkipCertificateCheck
    if ($response.StatusCode -eq 200) {
        Write-Host "✅ HTTPS connectivity OK" -ForegroundColor Green
    }
} catch {
    Write-Host "❌ HTTPS connectivity failed" -ForegroundColor Red
}

Write-Host "`n🎉 Production deployment completed!" -ForegroundColor Green
Write-Host "`nPost-deployment checklist:" -ForegroundColor Yellow
Write-Host "[ ] Update DNS records to point to this server"
Write-Host "[ ] Configure production SSL certificates (Let's Encrypt)"
Write-Host "[ ] Set up firewall rules (allow only 22, 80, 443)"
Write-Host "[ ] Configure automated backups"
Write-Host "[ ] Set up monitoring and logging"
Write-Host "[ ] Perform security scan"
Write-Host "[ ] Test all website functionality"

Write-Host "`nYour WordPress site should be available at:" -ForegroundColor Green
Write-Host "- HTTP:  http://$Domain"
Write-Host "- HTTPS: https://$Domain"
