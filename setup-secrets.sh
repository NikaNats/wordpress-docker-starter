#!/bin/bash

# Script to set up secrets for WordPress Docker Starter
# This script helps you securely generate and store passwords

set -euo pipefail

SECRETS_DIR="./secrets"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}WordPress Docker Starter - Secrets Setup${NC}"
echo "============================================="

# Create secrets directory if it doesn't exist
if [[ ! -d "$SECRETS_DIR" ]]; then
    mkdir -p "$SECRETS_DIR"
    echo -e "${GREEN}Created secrets directory${NC}"
fi

# Function to generate secure password
generate_password() {
    local length=${1:-16}
    if command -v openssl &> /dev/null; then
        openssl rand -base64 $length | tr -d "=+/" | cut -c1-$length
    elif command -v pwgen &> /dev/null; then
        pwgen -s $length 1
    else
        echo "$(date +%s)$(shuf -i 1000-9999 -n 1)" | sha256sum | cut -c1-$length
    fi
}

# Function to set up a secret
setup_secret() {
    local secret_name="$1"
    local secret_file="$SECRETS_DIR/$secret_name.txt"
    local description="$2"
    
    echo ""
    echo -e "${YELLOW}Setting up: $description${NC}"
    
    if [[ -f "$secret_file" ]]; then
        echo -e "${YELLOW}Secret file already exists: $secret_file${NC}"
        read -p "Do you want to overwrite it? (y/N): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            echo "Skipping $secret_name"
            return
        fi
    fi
    
    read -p "Enter password (or press Enter to generate one): " -s password
    echo
    
    if [[ -z "$password" ]]; then
        password=$(generate_password 20)
        echo -e "${GREEN}Generated secure password${NC}"
    fi
    
    echo "$password" > "$secret_file"
    chmod 600 "$secret_file" 2>/dev/null || true
    echo -e "${GREEN}Saved: $secret_file${NC}"
}

# Set up each secret
setup_secret "db_root_password" "MySQL Root Password"
setup_secret "db_password" "WordPress Database Password"
setup_secret "wp_admin_password" "WordPress Admin Password"

echo ""
echo -e "${GREEN}Secrets setup complete!${NC}"
echo ""
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Review your .env file for non-sensitive configuration"
echo "2. Run: docker-compose up -d"
echo "3. Your WordPress site will be available at the configured URL"
echo ""
echo -e "${RED}SECURITY REMINDER:${NC}"
echo "- The secrets/ directory is excluded from git"
echo "- Keep these files secure and back them up separately"
echo "- Never commit secret files to version control"
