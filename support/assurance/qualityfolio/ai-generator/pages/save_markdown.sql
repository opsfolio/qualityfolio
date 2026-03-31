-- /pages/save_markdown.sql
-- Saves markdown file to MARKDOWN_DESTINATION_PATH
--
-- The path comes from:
-- 1. database path_settings table (set via settings UI)
-- 2. Falls back to MARKDOWN_DESTINATION_PATH env var, then 'test-artifacts'
--
-- IMPORTANT: sqlpage.exec() calls are assigned to SET variables, NOT bare SELECTs.
-- Bare SELECT sqlpage.exec() causes SQLPage to render exec output as HTML before
-- the json component, which corrupts the JSON response the browser tries to parse.

-- Resolve destination once into a variable
SET _dest = COALESCE(
    (SELECT destination_path FROM path_settings 
     WHERE setting_key = 'markdown_destination' LIMIT 1),
    sqlpage.environment_variable('MARKDOWN_DESTINATION_PATH'),
    'test-artifacts'
);

-- Create the folder — absorb into SET variable to suppress HTML rendering
SET _mkdir_result = sqlpage.exec(
    'mkdir', '-p',
    '../' || $_dest
);

-- Write the markdown file — absorb into SET variable to suppress HTML rendering
SET _exec_result = sqlpage.exec(
    'sh',
    'scripts/write_markdown.sh',
    $_dest,
    :filename,
    :content
);

-- Return clean JSON — the ONLY thing rendered to the HTTP response body
SELECT 'json' AS component,
    json_object(
        'success', true,
        'folder', $_dest,
        'filename', :filename,
        'message', 'Markdown file saved successfully'
    ) AS value;