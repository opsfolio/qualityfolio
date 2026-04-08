-- /pages/settings/save_llm_keys.sql
-- Saves LLM API keys to DB and root .env

-- ============================================================
-- STEP 1: Save to database (app_settings)
-- ============================================================
DELETE FROM app_settings WHERE key IN ('openai_api_key', 'gemini_api_key', 'groq_api_key', 'anthropic_api_key');

INSERT INTO app_settings (key, value) VALUES 
('openai_api_key',    COALESCE(:openai_api_key, '')),
('gemini_api_key',    COALESCE(:gemini_api_key, '')),
('groq_api_key',      COALESCE(:groq_api_key, '')),
('anthropic_api_key', COALESCE(:anthropic_api_key, ''));

-- ============================================================
-- STEP 2: Update root .env
-- ============================================================
SELECT sqlpage.exec(
    'sh', '-c',
    '
# Find root .env
ENV_FILE=""
if [ -f "../../../.env" ]; then
    ENV_FILE="../../../.env"
elif [ -f "../.env" ]; then
    ENV_FILE="../.env"
fi

if [ -n "$ENV_FILE" ]; then
    update_env() {
        KEY=$1
        VAL=$2
        if grep -q "^$KEY=" "$ENV_FILE" 2>/dev/null; then
            sed -i "s|^$KEY=.*|$KEY=\"$VAL\"|" "$ENV_FILE"
        else
            echo "$KEY=\"$VAL\"" >> "$ENV_FILE"
        fi
    }

    update_env "OPENAI_API_KEY" "' || REPLACE(COALESCE(:openai_api_key, ''), '"', '\"') || '"
    update_env "GEMINI_API_KEY" "' || REPLACE(COALESCE(:gemini_api_key, ''), '"', '\"') || '"
    update_env "GROQ_API_KEY" "'   || REPLACE(COALESCE(:groq_api_key, ''), '"', '\"')   || '"
    update_env "ANTHROPIC_API_KEY" "' || REPLACE(COALESCE(:anthropic_api_key, ''), '"', '\"') || '"
fi
    '
) AS exec_result;

-- ============================================================
-- STEP 3: Redirect back
-- ============================================================
SELECT 'html' AS component,
       '<html><head>
          <meta http-equiv="refresh" content="0;url=/settings.sql?tab=llm_keys&success=API%20keys%20saved%20successfully" />
        </head><body></body></html>' AS html;
