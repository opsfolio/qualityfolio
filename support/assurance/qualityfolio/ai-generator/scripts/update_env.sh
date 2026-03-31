#!/usr/bin/env bash
# /scripts/update_env.sh
# Updates environment variables in .env file
# Usage: ./update_env.sh [env_file] [var_name] [var_value]
# Example: ./update_env.sh ".env" "MARKDOWN_DESTINATION_PATH" "./test-artifacts"

set -euo pipefail

# Parameters with defaults
ENV_FILE="${1:-.env}"
VAR_NAME="${2:-MARKDOWN_DESTINATION_PATH}"
NEW_VALUE="${3:-.test-artifacts}"

# Logging function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO] $1" >&2
}

error() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [ERROR] $1" >&2
    exit 1
}

# Validate inputs
if [ -z "$NEW_VALUE" ]; then
    error "No value provided for $VAR_NAME"
fi

log "Updating $VAR_NAME in $ENV_FILE"
log "New value: $NEW_VALUE"

# Create .env if it doesn't exist
if [ ! -f "$ENV_FILE" ]; then
    log "Creating $ENV_FILE"
    touch "$ENV_FILE" || error "Failed to create $ENV_FILE"
fi

# Verify file is writable
if [ ! -w "$ENV_FILE" ]; then
    error "$ENV_FILE is not writable. Check permissions."
fi

# Create a temporary file in the same directory for atomicity
TMP_FILE=$(mktemp "${ENV_FILE}.XXXXXX") || error "Failed to create temporary file"

# Function to clean up temp file on exit
cleanup() {
    rm -f "$TMP_FILE"
}
trap cleanup EXIT

# If variable exists, remove the old line; otherwise copy existing content
if grep -q "^${VAR_NAME}=" "$ENV_FILE" 2>/dev/null; then
    log "Updating existing variable"
    grep -v "^${VAR_NAME}=" "$ENV_FILE" > "$TMP_FILE" || true
else
    log "Adding new variable"
    cat "$ENV_FILE" > "$TMP_FILE" || error "Failed to copy $ENV_FILE"
fi

# Append the new variable assignment
echo "${VAR_NAME}=\"${NEW_VALUE}\"" >> "$TMP_FILE" || error "Failed to write to temporary file"

# Atomically replace the original file
mv "$TMP_FILE" "$ENV_FILE" || error "Failed to replace $ENV_FILE"

# Verify the update
if grep -q "^${VAR_NAME}=\"${NEW_VALUE}\"" "$ENV_FILE"; then
    log "✓ Successfully updated $VAR_NAME"
    echo "✓ $VAR_NAME=$NEW_VALUE" >&2
    exit 0
else
    error "Verification failed: Variable not found in $ENV_FILE after update"
fi