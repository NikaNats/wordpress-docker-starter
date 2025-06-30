#!/bin/bash
set -euo pipefail

# Load environment variables from .env file
if [[ -f .env ]]; then
    set -a
    source .env
    set +a
fi

# Validate required environment variables
if [[ -z "${DB_ROOT_PASSWORD:-}" ]]; then
    echo "Error: DB_ROOT_PASSWORD is not set. Please check your .env file." >&2
    exit 1
fi

if [[ -z "${WORDPRESS_DB_NAME:-}" ]]; then
    echo "Error: WORDPRESS_DB_NAME is not set. Please check your .env file." >&2
    exit 1
fi

# Validate arguments
if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <filename.sql>" >&2
    echo "       (Place the SQL file inside the 'wp-data' directory)" >&2
    exit 1
fi

readonly IMPORT_FILE_PATH="wp-data/$1"

# Validate file exists
if [[ ! -f "$IMPORT_FILE_PATH" ]]; then
    echo "Error: File '$IMPORT_FILE_PATH' not found." >&2
    exit 1
fi

# Check if db container is running
if ! docker compose ps db --status running --quiet > /dev/null 2>&1; then
    echo "Error: Database container is not running. Please start your Docker Compose stack first." >&2
    exit 1
fi

# Confirmation prompt
echo "⚠️  WARNING: This will completely overwrite the '${WORDPRESS_DB_NAME}' database with the contents of '$1'."
read -p "Are you sure you want to continue? (y/N): " -r

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Import cancelled."
    exit 0
fi

echo "Importing database from '$1'..."

# Import database
if docker compose exec -T db \
    env MYSQL_PWD="${DB_ROOT_PASSWORD}" \
    mysql -u root "${WORDPRESS_DB_NAME}" < "$IMPORT_FILE_PATH"; then
    echo "✅ Database import complete!"
else
    echo "❌ Database import failed!" >&2
    exit 1
fi