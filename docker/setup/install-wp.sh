#!/bin/bash
set -euo pipefail

readonly WP_CORE_FILE="/var/www/html/wp-load.php"
readonly MAX_WAIT_TIME=120
wait_time=0

echo "Setup script is waiting for WordPress core files..."

while [[ ! -f "$WP_CORE_FILE" ]] && [[ $wait_time -lt $MAX_WAIT_TIME ]]; do
    sleep 1
    ((wait_time++))
done

if [[ ! -f "$WP_CORE_FILE" ]]; then
    echo "Error: WordPress core files not found after ${MAX_WAIT_TIME}s timeout." >&2
    exit 1
fi

echo "WordPress core files found."

# Check if WordPress is already installed
if ! wp core is-installed --allow-root 2>/dev/null; then
    echo "WordPress is not installed. Installing now..."
    
    # Validate required environment variables
    for var in WP_URL WP_TITLE WP_ADMIN_USER WP_ADMIN_PASSWORD WP_ADMIN_EMAIL; do
        if [[ -z "${!var:-}" ]]; then
            echo "Error: Required environment variable $var is not set." >&2
            exit 1
        fi
    done
    
    # Install WordPress
    if wp core install \
        --url="$WP_URL" \
        --title="$WP_TITLE" \
        --admin_user="$WP_ADMIN_USER" \
        --admin_password="$WP_ADMIN_PASSWORD" \
        --admin_email="$WP_ADMIN_EMAIL" \
        --skip-email \
        --allow-root; then
        echo "✅ WordPress installed successfully."
    else
        echo "❌ WordPress installation failed!" >&2
        exit 1
    fi
else
    echo "WordPress is already installed. Skipping installation."
fi