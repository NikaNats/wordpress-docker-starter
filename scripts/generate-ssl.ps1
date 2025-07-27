# PowerShell script to generate SSL certificates for WordPress Docker Starter
# This script generates self-signed certificates for development
# For production, use Let's Encrypt or proper CA certificates

param(
    [string]$Domain = "localhost",
    [string]$Email = "admin@localhost"
)

$ErrorActionPreference = "Stop"

$SSLDir = "./config/ssl"

Write-Host "WordPress Docker Starter - SSL Certificate Setup" -ForegroundColor Green
Write-Host "=================================================="

# Create SSL directory if it doesn't exist
if (-not (Test-Path $SSLDir)) {
    New-Item -ItemType Directory -Path $SSLDir -Force | Out-Null
    Write-Host "Created SSL directory: $SSLDir" -ForegroundColor Green
}

# Check if certificates already exist
$certExists = (Test-Path "$SSLDir/cert.pem") -and (Test-Path "$SSLDir/key.pem")
if ($certExists) {
    Write-Host "SSL certificates already exist in $SSLDir" -ForegroundColor Yellow
    $overwrite = Read-Host "Do you want to regenerate them? (y/N)"
    if ($overwrite -notmatch "^[Yy]$") {
        Write-Host "Keeping existing certificates."
        exit 0
    }
}

Write-Host "Generating SSL certificates for domain: $Domain" -ForegroundColor Yellow

# Check if OpenSSL is available
try {
    $null = Get-Command openssl -ErrorAction Stop
} catch {
    Write-Host "Error: OpenSSL is not installed or not in PATH" -ForegroundColor Red
    Write-Host "Please install OpenSSL from: https://slproweb.com/products/Win32OpenSSL.html" -ForegroundColor Red
    Write-Host "Or use Windows Subsystem for Linux (WSL) to run the generate-ssl.sh script" -ForegroundColor Yellow
    exit 1
}

try {
    # Generate private key
    Write-Host "Generating private key..."
    & openssl genrsa -out "$SSLDir/key.pem" 4096
    
    # Generate certificate signing request
    Write-Host "Generating certificate signing request..."
    & openssl req -new -key "$SSLDir/key.pem" -out "$SSLDir/csr.pem" -subj "/C=US/ST=State/L=City/O=Organization/OU=OrgUnit/CN=$Domain/emailAddress=$Email"
    
    # Create config file for certificate extensions
    $configContent = @"
[v3_req]
keyUsage = keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth
subjectAltName = DNS:$Domain,DNS:www.$Domain,DNS:localhost,IP:127.0.0.1
"@
    $configFile = "$SSLDir/cert.conf"
    $configContent | Out-File -FilePath $configFile -Encoding utf8
    
    # Generate self-signed certificate (valid for 365 days)
    Write-Host "Generating self-signed certificate..."
    & openssl x509 -req -days 365 -in "$SSLDir/csr.pem" -signkey "$SSLDir/key.pem" -out "$SSLDir/cert.pem" -extensions v3_req -extfile $configFile
    
    # Generate Diffie-Hellman parameters (for enhanced security)
    Write-Host "Generating Diffie-Hellman parameters (this may take a while)..."
    & openssl dhparam -out "$SSLDir/dhparam.pem" 2048
    
    # Clean up temporary files
    Remove-Item "$SSLDir/csr.pem" -Force
    Remove-Item $configFile -Force
    
    Write-Host "✅ SSL certificates generated successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Generated files:"
    Write-Host "  - $SSLDir/cert.pem (Certificate)"
    Write-Host "  - $SSLDir/key.pem (Private Key)"
    Write-Host "  - $SSLDir/dhparam.pem (DH Parameters)"
    Write-Host ""
    Write-Host "For production use:" -ForegroundColor Yellow
    Write-Host "Replace self-signed certificates with proper CA certificates"
    Write-Host "Consider using Let's Encrypt with certbot for free SSL certificates"
    Write-Host ""
    Write-Host "Security Note:" -ForegroundColor Red
    Write-Host "Self-signed certificates will show security warnings in browsers"
    Write-Host "Users will need to accept the certificate manually"

} catch {
    Write-Host "Error generating SSL certificates: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "Please check that OpenSSL is properly installed and try again." -ForegroundColor Yellow
    exit 1
}
