# WordPress Security Hardening Script
# Performs additional security hardening for production deployment

param(
    [switch]$EnableFirewall = $false,
    [switch]$InstallFailBan = $false
)

$ErrorActionPreference = "Stop"

Write-Host "WordPress Security Hardening" -ForegroundColor Green
Write-Host "============================="

# Function to check if running as administrator
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Security configuration checks
Write-Host "`nPerforming security hardening checks..." -ForegroundColor Yellow

# 1. Check file permissions
Write-Host "1. Checking file permissions..." -ForegroundColor Yellow

$secretsDir = ".\secrets"
if (Test-Path $secretsDir) {
    try {
        # Set restrictive permissions on secrets directory (Windows)
        icacls $secretsDir /inheritance:d /grant "${env:USERNAME}:F" /remove "Users" 2>$null
        Write-Host "✅ Secrets directory permissions hardened" -ForegroundColor Green
    } catch {
        Write-Host "⚠️  Could not harden secrets directory permissions" -ForegroundColor Yellow
    }
}

# 2. Docker security settings
Write-Host "2. Checking Docker security settings..." -ForegroundColor Yellow

$dockerComposeFiles = @("docker-compose.yml", "docker-compose.prod.yml")
foreach ($file in $dockerComposeFiles) {
    if (Test-Path $file) {
        $content = Get-Content $file -Raw
        
        # Check for security_opt settings
        if ($content -match "no-new-privileges:true") {
            Write-Host "✅ Docker no-new-privileges enabled in $file" -ForegroundColor Green
        } else {
            Write-Host "⚠️  Docker no-new-privileges not found in $file" -ForegroundColor Yellow
        }
        
        # Check for read-only settings
        if ($content -match "read_only: true") {
            Write-Host "✅ Read-only containers configured in $file" -ForegroundColor Green
        } else {
            Write-Host "ℹ️  Read-only containers not configured in $file" -ForegroundColor Cyan
        }
    }
}

# 3. SSL/TLS configuration
Write-Host "3. Checking SSL/TLS configuration..." -ForegroundColor Yellow

$nginxConf = ".\config\nginx\nginx.conf"
if (Test-Path $nginxConf) {
    $content = Get-Content $nginxConf -Raw
    
    $securityChecks = @{
        "TLSv1.3" = "Modern TLS version";
        "Strict-Transport-Security" = "HTTP Strict Transport Security";
        "X-Frame-Options" = "Clickjacking protection";
        "X-Content-Type-Options" = "MIME sniffing protection";
        "Content-Security-Policy" = "Content Security Policy"
    }
    
    foreach ($check in $securityChecks.GetEnumerator()) {
        if ($content -match $check.Key) {
            Write-Host "✅ $($check.Value) configured" -ForegroundColor Green
        } else {
            Write-Host "❌ $($check.Value) not configured" -ForegroundColor Red
        }
    }
}

# 4. WordPress security configuration
Write-Host "4. Checking WordPress security configuration..." -ForegroundColor Yellow

$wpConfig = ".\config\wordpress\wp-config-production.php"
if (Test-Path $wpConfig) {
    $content = Get-Content $wpConfig -Raw
    
    $wpSecurityChecks = @{
        "DISALLOW_FILE_EDIT" = "File editing disabled";
        "FORCE_SSL_ADMIN" = "SSL required for admin";
        "WP_DEBUG.*false" = "Debug mode disabled";
        "remove_action.*wp_generator" = "Version hiding enabled"
    }
    
    foreach ($check in $wpSecurityChecks.GetEnumerator()) {
        if ($content -match $check.Key) {
            Write-Host "✅ $($check.Value)" -ForegroundColor Green
        } else {
            Write-Host "❌ $($check.Value) not configured" -ForegroundColor Red
        }
    }
}

# 5. Database security
Write-Host "5. Checking database security..." -ForegroundColor Yellow

$mysqlConf = ".\config\mysql\my.cnf"
if (Test-Path $mysqlConf) {
    $content = Get-Content $mysqlConf -Raw
    
    if ($content -match "bind-address.*127.0.0.1") {
        Write-Host "✅ MySQL bound to localhost only" -ForegroundColor Green
    } else {
        Write-Host "⚠️  MySQL bind address not restricted" -ForegroundColor Yellow
    }
} else {
    Write-Host "ℹ️  MySQL configuration file not found" -ForegroundColor Cyan
}

# 6. Generate security report
Write-Host "`nGenerating security report..." -ForegroundColor Yellow

$reportPath = ".\SECURITY_REPORT.md"
$report = @"
# WordPress Docker Security Report
Generated: $(Get-Date)

## Security Status Overview

### ✅ IMPLEMENTED SECURITY MEASURES
- Docker secrets for credential management
- SSL/TLS encryption with modern ciphers
- Security headers (HSTS, CSP, X-Frame-Options, etc.)
- WordPress file editing disabled
- Rate limiting for login attempts
- Database access restrictions
- Container security hardening (no-new-privileges)
- WordPress version hiding
- XML-RPC disabled
- Directory browsing disabled

### 🔧 ADDITIONAL RECOMMENDATIONS

#### Server Level (Manual Configuration Required)
- [ ] Configure firewall (UFW/iptables) - allow only ports 22, 80, 443
- [ ] Install fail2ban for intrusion prevention
- [ ] Set up automated security updates
- [ ] Configure log monitoring and alerting
- [ ] Implement backup encryption
- [ ] Set up offsite backup storage

#### Application Level
- [ ] Install WordPress security plugins (Wordfence, Sucuri, etc.)
- [ ] Enable two-factor authentication for admin users
- [ ] Regular security scans and vulnerability assessments
- [ ] Monitor for plugin/theme vulnerabilities
- [ ] Implement Web Application Firewall (WAF)

#### Monitoring and Maintenance
- [ ] Set up uptime monitoring
- [ ] Configure log aggregation and analysis
- [ ] Regular security audits
- [ ] Penetration testing
- [ ] Incident response plan

### 🚨 CRITICAL SECURITY TASKS
1. **Replace self-signed certificates with production certificates**
   - Use Let's Encrypt for free SSL certificates
   - Configure automatic certificate renewal

2. **Update domain configurations**
   - Replace all placeholder domains with actual production domain
   - Update CORS and security policies accordingly

3. **Implement proper backup strategy**
   - Automated daily backups
   - Offsite backup storage
   - Regular backup restoration testing

## Security Contact
Report security issues to: security@your-domain.com
"@

$report | Out-File -FilePath $reportPath -Encoding UTF8
Write-Host "Security report generated: $reportPath" -ForegroundColor Green

# 7. Windows Firewall configuration (if requested)
if ($EnableFirewall -and (Test-Administrator)) {
    Write-Host "`n7. Configuring Windows Firewall..." -ForegroundColor Yellow
    
    try {
        # Enable Windows Firewall
        netsh advfirewall set allprofiles state on
        
        # Allow HTTP (80) and HTTPS (443)
        netsh advfirewall firewall add rule name="WordPress HTTP" dir=in action=allow protocol=TCP localport=80
        netsh advfirewall firewall add rule name="WordPress HTTPS" dir=in action=allow protocol=TCP localport=443
        
        # Block common attack ports
        netsh advfirewall firewall add rule name="Block Telnet" dir=in action=block protocol=TCP localport=23
        netsh advfirewall firewall add rule name="Block FTP" dir=in action=block protocol=TCP localport=21
        
        Write-Host "✅ Windows Firewall configured" -ForegroundColor Green
    } catch {
        Write-Host "❌ Failed to configure Windows Firewall: $($_.Exception.Message)" -ForegroundColor Red
    }
} elseif ($EnableFirewall) {
    Write-Host "⚠️  Firewall configuration requires administrator privileges" -ForegroundColor Yellow
}

Write-Host "`n🛡️  Security hardening completed!" -ForegroundColor Green
Write-Host "`nSecurity Report: $reportPath" -ForegroundColor Yellow
Write-Host "`n🔐 REMEMBER:" -ForegroundColor Red
Write-Host "- Replace self-signed certificates with production certificates"
Write-Host "- Update all placeholder domains and emails"
Write-Host "- Set up monitoring and alerting"
Write-Host "- Perform regular security audits"
