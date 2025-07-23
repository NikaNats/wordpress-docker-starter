#!/bin/bash
set -euo pipefail

readonly WP_CORE_FILE="/var/www/html/wp-load.php"

# Function for logging
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

# Function for loading secrets (this will be run by root before user switch)
load_secret() {
    local secret_name="$1"
    local secret_file="/run/secrets/$secret_name"
    # Note: Environment variable based secrets won't be available
    # as we are switching user, but file-based secrets will work.
    if [[ -f "$secret_file" ]]; then
        cat "$secret_file"
    else
        echo "" # Return empty if not found
    fi
}

log "Starting WordPress installation process (running as user: $(whoami))"

# Download WordPress core if not present
if [[ ! -f "$WP_CORE_FILE" ]]; then
    log "WordPress core files not found. Downloading..."
    wp core download --quiet
    log "WordPress core files downloaded."
else
    log "WordPress core files found."
fi

# Check if WordPress is already installed
if ! wp core is-installed --path='/var/www/html' 2>/dev/null; then
    log "WordPress is not installed. Installing now..."

    # Load secrets into variables (still loaded by root before user switch)
    WORDPRESS_DB_PASSWORD=$(load_secret "db_password")
    WP_ADMIN_PASSWORD=$(load_secret "wp_admin_password")

    # wp-config.php will be created with correct ownership
    if [[ ! -f "/var/www/html/wp-config.php" ]]; then
        log "wp-config.php not found. Creating..."
        wp config create \
            --dbname="$WORDPRESS_DB_NAME" \
            --dbuser="$WORDPRESS_DB_USER" \
            --dbpass="$WORDPRESS_DB_PASSWORD" \
            --dbhost="$WORDPRESS_DB_HOST" \
            --skip-check \
            --quiet
        
        # Add filesystem method to bypass FTP requirements
        log "Adding FS_METHOD constant to wp-config.php..."
        wp config set FS_METHOD 'direct' --type=constant --quiet
        
        log "wp-config.php created with filesystem constants."
    fi

    log "Installing WordPress core..."
    wp core install \
        --url="$WP_URL" \
        --title="$WP_TITLE" \
        --admin_user="$WP_ADMIN_USER" \
        --admin_password="$WP_ADMIN_PASSWORD" \
        --admin_email="$WP_ADMIN_EMAIL" \
        --skip-email \
        --quiet
    log "✅ WordPress installed successfully."
else
    log "WordPress is already installed. Skipping installation."
fi

log "WordPress setup completed successfully."