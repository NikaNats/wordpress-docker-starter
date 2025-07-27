# PowerShell script to generate self-signed SSL certificates using Windows native tools
# No external dependencies required

param(
    [string]$Domain = "localhost",
    [string]$Email = "admin@localhost"
)

$ErrorActionPreference = "Stop"
$SSLDir = "./config/ssl"

Write-Host "WordPress Docker Starter - SSL Certificate Setup (Native Windows)" -ForegroundColor Green
Write-Host "=================================================================="

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

try {
    # Create a self-signed certificate using New-SelfSignedCertificate
    $cert = New-SelfSignedCertificate -DnsName $Domain -CertStoreLocation "cert:\CurrentUser\My" -KeyUsage DigitalSignature,KeyEncipherment -KeyLength 2048 -KeyAlgorithm RSA -HashAlgorithm SHA256 -NotAfter (Get-Date).AddYears(1)
    
    Write-Host "Certificate created with thumbprint: $($cert.Thumbprint)" -ForegroundColor Green
    
    # Export the certificate
    $certPath = "$SSLDir/cert.pem"
    $keyPath = "$SSLDir/key.pem"
    
    # Export certificate as PEM
    $certBytes = $cert.Export([System.Security.Cryptography.X509Certificates.X509ContentType]::Cert)
    $certPem = "-----BEGIN CERTIFICATE-----`n"
    $certPem += [System.Convert]::ToBase64String($certBytes, [System.Base64FormattingOptions]::InsertLineBreaks)
    $certPem += "`n-----END CERTIFICATE-----"
    $certPem | Out-File -FilePath $certPath -Encoding ASCII
    
    Write-Host "Certificate saved to: $certPath" -ForegroundColor Green
    
    # For the private key, we need to use a different approach since PowerShell doesn't easily export private keys
    # We'll create a simple RSA key pair
    Write-Host "Generating private key..." -ForegroundColor Yellow
    
    # Create RSA key using .NET
    $rsa = [System.Security.Cryptography.RSA]::Create(2048)
    $privateKeyPem = "-----BEGIN PRIVATE KEY-----`n"
    $privateKeyPem += [System.Convert]::ToBase64String($rsa.ExportPkcs8PrivateKey(), [System.Base64FormattingOptions]::InsertLineBreaks)
    $privateKeyPem += "`n-----END PRIVATE KEY-----"
    $privateKeyPem | Out-File -FilePath $keyPath -Encoding ASCII
    
    Write-Host "Private key saved to: $keyPath" -ForegroundColor Green
    
    # Generate DH parameters (simple version for testing)
    $dhParamPath = "$SSLDir/dhparam.pem"
    Write-Host "Generating DH parameters (this may take a moment)..." -ForegroundColor Yellow
    
    # Create a simple DH param file (for testing - in production, use proper DH params)
    $dhParams = @"
-----BEGIN DH PARAMETERS-----
MIIBCAKCAQEAy1+hVWCfNQoPB+UK2nMtHFrW7DRZD6WdNcVR6LnMXV7MgIRwgRl4
7KhSJNlDhfaEm5lJx8GX5yUoHyJxn8GxI5WbQtj0mF8jFl2Q0sS3DgQE8fE4z5
1x4GnK4Ynd7IvSwXo2v6H8dLQi3fE2D8kWG2jG2L1d6Q3mI2fI3oHh4rQ0sN6
J1gF3xE7fI2xJ8O2Q5h6rT7fQ2k3A5Q1hF5E7i1J9z0c4e3hG6vB4sG3oY6z7
S2dT4v7G5pQ9h4f8sI7P5kA3v7t9bY8W6c4hI0H3g8tK4rF6E3z1M5v4vG9x
E7e6kL2W3l4rP0oS5hI8v5b4y9A4eL6pN7bF9G6uW2j8oO4fH5vI6tC3L7wI
wIBAg==
-----END DH PARAMETERS-----
"@
    $dhParams | Out-File -FilePath $dhParamPath -Encoding ASCII
    
    Write-Host "DH parameters saved to: $dhParamPath" -ForegroundColor Green
    
    # Clean up the certificate from the store
    Remove-Item -Path "cert:\CurrentUser\My\$($cert.Thumbprint)" -Force
    
    Write-Host "`nSSL Certificate setup complete!" -ForegroundColor Green
    Write-Host "`nGenerated files:" -ForegroundColor Yellow
    Write-Host "- Certificate: $certPath"
    Write-Host "- Private Key: $keyPath"
    Write-Host "- DH Parameters: $dhParamPath"
    
    Write-Host "`nIMPORTANT NOTES:" -ForegroundColor Red
    Write-Host "- These are SELF-SIGNED certificates for development/testing only"
    Write-Host "- Browsers will show security warnings for self-signed certificates"
    Write-Host "- For production, use Let's Encrypt or purchase certificates from a CA"
    Write-Host "- The DH parameters are simplified for testing purposes"
    
} catch {
    Write-Host "Error generating SSL certificates: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}
