#!/usr/bin/env sh
# scripts/write_markdown.sh
# Writes markdown file to destination folder
#
# Called by save_markdown.sql via sqlpage.exec()
# Args:
#   $1 = folder name (relative to qualityfolio root) e.g. "test-artifacts"
#   $2 = filename                                      e.g. "My_Project_REQ-001.md"
#   $3 = markdown content (full text)
#
# SQLPage runs from ai-generator/, so qualityfolio root is ../
# The file is written to ../<folder>/<filename>

set -e  # Exit on error

FOLDER="$1"
FILENAME="$2"
CONTENT="$3"

# Validate inputs
if [ -z "$FOLDER" ] || [ -z "$FILENAME" ] || [ -z "$CONTENT" ]; then
    echo "ERROR: Missing required arguments (folder, filename, content)" >&2
    exit 1
fi

# Sanitise filename — strip path separators to prevent traversal attacks
SAFE_FILENAME=$(basename "$FILENAME")

# Ensure it ends with .md
case "$SAFE_FILENAME" in
  *.md) ;;
  *) SAFE_FILENAME="${SAFE_FILENAME}.md" ;;
esac

# Build destination path
# If FOLDER is an absolute path (set via MARKDOWN_DESTINATION_PATH env), use it directly.
# If relative, prepend ../ to resolve from qualityfolio root (since SQLPage runs from ai-generator/).
case "$FOLDER" in
  /*) DEST_DIR="$FOLDER" ;;
  *)  DEST_DIR="../$FOLDER" ;;
esac

# ✓ CREATE FOLDER IF IT DOESN'T EXIST
if ! mkdir -p "$DEST_DIR" 2>/dev/null; then
    echo "ERROR: Could not create directory: $DEST_DIR" >&2
    exit 1
fi

# ✓ VERIFY FOLDER WAS CREATED AND IS WRITABLE
if [ ! -d "$DEST_DIR" ]; then
    echo "ERROR: Directory does not exist after creation: $DEST_DIR" >&2
    exit 1
fi

if [ ! -w "$DEST_DIR" ]; then
    echo "ERROR: Directory is not writable: $DEST_DIR" >&2
    exit 1
fi

FILEPATH="$DEST_DIR/$SAFE_FILENAME"

# ✓ WRITE CONTENT SAFELY WITH ERROR HANDLING
if ! printf '%s' "$CONTENT" > "$FILEPATH"; then
    echo "ERROR: Could not write file: $FILEPATH" >&2
    exit 1
fi

# ✓ VERIFY FILE WAS CREATED AND IS READABLE
if [ ! -f "$FILEPATH" ]; then
    echo "ERROR: File was not created: $FILEPATH" >&2
    exit 1
fi

if [ ! -r "$FILEPATH" ]; then
    echo "ERROR: File is not readable: $FILEPATH" >&2
    exit 1
fi

# ✓ SUCCESS - print the full path
echo "OK: $FILEPATH"
exit 0