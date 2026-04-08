-- /pages/settings/save_database_path.sql
-- Updates DB path in path_settings table and .env files

-- ============================================================
-- STEP 1: Upsert into database
-- ============================================================
UPDATE path_settings
SET destination_path = :database_path,
    updated_at       = CURRENT_TIMESTAMP
WHERE setting_key = 'database_path';

INSERT OR IGNORE INTO path_settings (setting_key, destination_path, description, updated_at)
VALUES (
    'database_path',
    :database_path,
    'Path to the Resource Surveillance SQLite database',
    CURRENT_TIMESTAMP
);

-- ============================================================
-- STEP 2: Update ai-chat/.env file
-- ============================================================
SELECT sqlpage.exec(
    'sh', '-c',
    '
DB_PATH="' || REPLACE(REPLACE(COALESCE(:database_path, ''), '\', '\\'), '"', '\"') || '"

# Find ai-chat/.env relative to common project structures
CHAT_ENV=""
if [ -f "../ai-chat/.env" ]; then
    CHAT_ENV="../ai-chat/.env"
elif [ -f "../../../ai-chat/.env" ]; then
    CHAT_ENV="../../../ai-chat/.env"
fi

if [ -n "$CHAT_ENV" ]; then
    if grep -q "^RSSD_PATH=" "$CHAT_ENV" 2>/dev/null; then
        sed -i "s|^RSSD_PATH=.*|RSSD_PATH=\"$DB_PATH\"|" "$CHAT_ENV"
    else
        echo "RSSD_PATH=\"$DB_PATH\"" >> "$CHAT_ENV"
    fi
fi
    '
) AS exec_result;

-- ============================================================
-- STEP 3: Redirect back
-- ============================================================
SELECT 'html' AS component,
       '<html><head>
          <meta http-equiv="refresh" content="0;url=/settings.sql?tab=database_path&success=Database%20path%20saved%20successfully" />
        </head><body></body></html>' AS html;
