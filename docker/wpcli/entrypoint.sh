#!/bin/bash
set -euo pipefail

readonly WP_CORE_FILE="${WP_CORE_FILE:-/var/www/html/wp-load.php}"
readonly MAX_WAIT_TIME="${MAX_WAIT_TIME:-60}"
wait_time=0

echo "WP-CLI waiting for WordPress core files at: $WP_CORE_FILE"

while [[ ! -f "$WP_CORE_FILE" ]] && [[ $wait_time -lt $MAX_WAIT_TIME ]]; do
    sleep 1
    ((wait_time++))
    if (( wait_time % 10 == 0 )); then
        echo "Still waiting... ${wait_time}s elapsed"
    fi
done

if [[ ! -f "$WP_CORE_FILE" ]]; then
    echo "Error: WordPress core files not found after ${MAX_WAIT_TIME}s timeout." >&2
    echo "Check if WordPress container is running and volumes are mounted correctly." >&2
    exit 1
fi

echo "WordPress core files found after ${wait_time}s. Starting WP-CLI."
exec "$@"