#!/bin/bash
set -euo pipefail

# Load environment variables
if [[ -f .env ]]; then
    set -a
    source .env
    set +a
fi

# Validate required variables
[[ -z "${DB_ROOT_PASSWORD:-}" ]] && { echo "Error: DB_ROOT_PASSWORD not set" >&2; exit 1; }
[[ -z "${WORDPRESS_DB_NAME:-}" ]] && { echo "Error: WORDPRESS_DB_NAME not set" >&2; exit 1; }

# Configuration
readonly BACKUP_DIR="wp-data"
readonly BACKUP_FILE="$BACKUP_DIR/backup_$(date +%Y%m%d_%H%M%S).sql"

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Check if database container is running
if ! docker compose ps db --status running -q >/dev/null 2>&1; then
    echo "Error: Database container not running. Start with: docker compose up -d" >&2
    exit 1
fi

echo "Backing up database '$WORDPRESS_DB_NAME'..."

# Create backup with cleanup on failure
if docker compose exec -T db \
    env MYSQL_PWD="$DB_ROOT_PASSWORD" \
    mysqldump -u root \
    --single-transaction \
    --routines \
    --triggers \
    --no-tablespaces \
    "$WORDPRESS_DB_NAME" > "$BACKUP_FILE"; then
    
    # Verify backup was created
    if [[ -s "$BACKUP_FILE" ]]; then
        echo "✅ Backup complete: $BACKUP_FILE ($(du -h "$BACKUP_FILE" | cut -f1))"
    else
        echo "❌ Backup failed: empty file" >&2
        rm -f "$BACKUP_FILE"
        exit 1
    fi
else
    echo "❌ Backup failed" >&2
    rm -f "$BACKUP_FILE"
    exit 1
fi

# Clean up backups older than 7 days
find "$BACKUP_DIR" -name "backup_*.sql" -mtime +7 -delete 2>/dev/null || true

echo "Backup saved to: $BACKUP_FILE"