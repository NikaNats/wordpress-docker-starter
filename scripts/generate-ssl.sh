#!/bin/bash
# SSL Certificate Generation Script for WordPress Docker Starter
# This script generates self-signed certificates for development
# For production, use Let's Encrypt or proper CA certificates

set -euo pipefail

SSL_DIR="./config/ssl"
DOMAIN="${SSL_DOMAIN:-localhost}"
EMAIL="${SSL_EMAIL:-admin@localhost}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}WordPress Docker Starter - SSL Certificate Setup${NC}"
echo "=================================================="

# Create SSL directory if it doesn't exist
mkdir -p "$SSL_DIR"

# Check if certificates already exist
if [[ -f "$SSL_DIR/cert.pem" && -f "$SSL_DIR/key.pem" ]]; then
    echo -e "${YELLOW}SSL certificates already exist in $SSL_DIR${NC}"
    read -p "Do you want to regenerate them? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        echo "Keeping existing certificates."
        exit 0
    fi
fi

echo -e "${YELLOW}Generating SSL certificates for domain: $DOMAIN${NC}"

# Generate private key
echo "Generating private key..."
openssl genrsa -out "$SSL_DIR/key.pem" 4096

# Generate certificate signing request
echo "Generating certificate signing request..."
openssl req -new -key "$SSL_DIR/key.pem" -out "$SSL_DIR/csr.pem" -subj "/C=US/ST=State/L=City/O=Organization/OU=OrgUnit/CN=$DOMAIN/emailAddress=$EMAIL"

# Generate self-signed certificate (valid for 365 days)
echo "Generating self-signed certificate..."
openssl x509 -req -days 365 -in "$SSL_DIR/csr.pem" -signkey "$SSL_DIR/key.pem" -out "$SSL_DIR/cert.pem" \
    -extensions v3_req -extfile <(echo "
[v3_req]
keyUsage = keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth
subjectAltName = DNS:$DOMAIN,DNS:www.$DOMAIN,DNS:localhost,IP:127.0.0.1
")

# Generate Diffie-Hellman parameters (for enhanced security)
echo "Generating Diffie-Hellman parameters (this may take a while)..."
openssl dhparam -out "$SSL_DIR/dhparam.pem" 2048

# Clean up CSR file
rm "$SSL_DIR/csr.pem"

# Set proper permissions
chmod 600 "$SSL_DIR/key.pem"
chmod 644 "$SSL_DIR/cert.pem"
chmod 644 "$SSL_DIR/dhparam.pem"

echo -e "${GREEN}✅ SSL certificates generated successfully!${NC}"
echo ""
echo "Generated files:"
echo "  - $SSL_DIR/cert.pem (Certificate)"
echo "  - $SSL_DIR/key.pem (Private Key)"
echo "  - $SSL_DIR/dhparam.pem (DH Parameters)"
echo ""
echo -e "${YELLOW}For production use:${NC}"
echo "Replace self-signed certificates with proper CA certificates"
echo "Consider using Let's Encrypt with certbot for free SSL certificates"
echo ""
echo -e "${RED}Security Note:${NC}"
echo "Self-signed certificates will show security warnings in browsers"
echo "Users will need to accept the certificate manually"
