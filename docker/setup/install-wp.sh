#!/bin/bash
set -euo pipefail

readonly WP_CORE_FILE="/var/www/html/wp-load.php"
readonly MAX_WAIT_TIME=120

# Function for logging
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

log "Starting WordPress installation process..."

# Download WordPress core if not present
if [[ ! -f "$WP_CORE_FILE" ]]; then
    log "WordPress core files not found. Downloading..."
    wp core download --allow-root --quiet
    log "WordPress core files downloaded."
else
    log "WordPress core files found."
fi

# Check if WordPress is already installed
if ! wp core is-installed --allow-root 2>/dev/null; then
    log "WordPress is not installed. Installing now..."

    # Validate required environment variables
    required_vars=(
        "WORDPRESS_DB_NAME"
        "WORDPRESS_DB_USER" 
        "WORDPRESS_DB_PASSWORD"
        "WORDPRESS_DB_HOST"
        "WP_URL"
        "WP_TITLE"
        "WP_ADMIN_USER"
        "WP_ADMIN_PASSWORD"
        "WP_ADMIN_EMAIL"
    )
    
    for var in "${required_vars[@]}"; do
        if [[ -z "${!var:-}" ]]; then
            log "Error: Required environment variable $var is not set."
            exit 1
        fi
    done

    # Create wp-config.php if it does not exist
    if [[ ! -f "/var/www/html/wp-config.php" ]]; then
        log "wp-config.php not found. Creating..."
        wp config create \
            --dbname="$WORDPRESS_DB_NAME" \
            --dbuser="$WORDPRESS_DB_USER" \
            --dbpass="$WORDPRESS_DB_PASSWORD" \
            --dbhost="$WORDPRESS_DB_HOST" \
            --dbcharset="${MYSQL_CHARSET:-utf8mb4}" \
            --dbcollate="${MYSQL_COLLATION:-utf8mb4_unicode_ci}" \
            --skip-check \
            --allow-root \
            --quiet
        log "wp-config.php created."
    fi

    # Install WordPress with retry logic
    install_attempts=0
    max_attempts=3
    
    while [[ $install_attempts -lt $max_attempts ]]; do
        if wp core install \
            --url="$WP_URL" \
            --title="$WP_TITLE" \
            --admin_user="$WP_ADMIN_USER" \
            --admin_password="$WP_ADMIN_PASSWORD" \
            --admin_email="$WP_ADMIN_EMAIL" \
            --skip-email \
            --allow-root \
            --quiet; then
            log "✅ WordPress installed successfully."
            break
        else
            ((install_attempts++))
            if [[ $install_attempts -lt $max_attempts ]]; then
                log "WordPress installation failed. Retrying ($install_attempts/$max_attempts)..."
                sleep 5
            else
                log "❌ WordPress installation failed after $max_attempts attempts!"
                exit 1
            fi
        fi
    done
    
    # Set proper file permissions
    find /var/www/html -type d -exec chmod 755 {} \;
    find /var/www/html -type f -exec chmod 644 {} \;
    chmod 600 /var/www/html/wp-config.php
    
else
    log "WordPress is already installed. Skipping installation."
fi

log "WordPress setup completed successfully."