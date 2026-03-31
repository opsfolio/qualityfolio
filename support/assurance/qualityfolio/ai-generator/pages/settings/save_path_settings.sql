-- /pages/settings/save_path_settings.sql
-- Does DB upsert + folder creation + .env update,
-- then uses an HTML meta-refresh to navigate the browser to settings.sql.
--
-- WHY NOT 'redirect' COMPONENT:
--   SQLPage requires 'redirect' to be the very first component with no
--   prior output. Since sqlpage.exec() outputs a row (EXEC_RESULT),
--   the redirect component errors. The workaround is to emit a tiny
--   HTML page with <meta http-equiv="refresh"> which the browser honours
--   immediately — same user experience as a redirect, no SQLPage conflict.

-- ============================================================
-- STEP 1: Upsert into database (store bare folder name)
-- ============================================================
UPDATE path_settings
SET destination_path = :artifact_destination,
    updated_at       = CURRENT_TIMESTAMP
WHERE setting_key = 'markdown_destination';

INSERT OR IGNORE INTO path_settings (setting_key, destination_path, description, updated_at)
VALUES (
    'markdown_destination',
    :artifact_destination,
    'Destination path where generated test artifacts and reports are saved',
    CURRENT_TIMESTAMP
);

-- ============================================================
-- STEP 2 & 3: Create folder in qualityfolio root + update .env
--
-- User types:  "test-artifacts"
-- Folder created at:  ../test-artifacts  (qualityfolio root)
-- Value in .env:      MARKDOWN_DESTINATION_PATH="./test-artifacts"
--   (./prefix is what qualityfolio.md expects for surveilr ingest)
-- ============================================================
SELECT sqlpage.exec(
    'sh', '-c',
    '
RAW_INPUT="' || REPLACE(REPLACE(:artifact_destination, '\', '\\'), '"', '\"') || '"

# Strip any leading ./ or ../ or / so we get a bare folder name
FOLDER_NAME=$(echo "$RAW_INPUT" | sed "s|^\.\./||; s|^\./||; s|^/||")

# Fallback: if stripping left nothing, use raw input
if [ -z "$FOLDER_NAME" ]; then
    FOLDER_NAME="$RAW_INPUT"
fi

# Full path to create: relative to qualityfolio root (parent of ai-generator)
DEST_PATH="../$FOLDER_NAME"

# Create the folder in qualityfolio root if it does not exist
if [ ! -d "$DEST_PATH" ]; then
    mkdir -p "$DEST_PATH" 2>/dev/null
fi

# The env value must be ./folder-name as expected by qualityfolio.md
ENV_VALUE="./$FOLDER_NAME"

# Upsert MARKDOWN_DESTINATION_PATH in qualityfolio/.env
ENV_FILE="../.env"
touch "$ENV_FILE" 2>/dev/null || (mkdir -p "$(dirname "$ENV_FILE")" && touch "$ENV_FILE")

if grep -q "^MARKDOWN_DESTINATION_PATH=" "$ENV_FILE" 2>/dev/null; then
    sed -i "s|^MARKDOWN_DESTINATION_PATH=.*|MARKDOWN_DESTINATION_PATH=\"$ENV_VALUE\"|" "$ENV_FILE"
else
    echo "MARKDOWN_DESTINATION_PATH=\"$ENV_VALUE\"" >> "$ENV_FILE"
fi
    '
) AS exec_result;

-- ============================================================
-- STEP 4: Meta-refresh redirect to settings page.
--   Uses <meta http-equiv="refresh"> because SQLPage's redirect
--   component requires no prior output — which exec_result violates.
--   The browser treats a 0-second meta refresh identically to a redirect.
-- ============================================================
SELECT 'html' AS component,
       '<html><head>
          <meta http-equiv="refresh" content="0;url=/settings.sql?tab=markdown_paths&success=Path%20saved%20successfully" />
        </head><body></body></html>' AS html;