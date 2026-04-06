-- /pages/save_markdown.sql
-- Saves markdown file to MARKDOWN_DESTINATION_PATH with proper error handling
--
-- The path comes from:
-- 1. database path_settings table (set via settings UI)
-- 2. Falls back to MARKDOWN_DESTINATION_PATH env var, then 'test-artifacts'
--
-- CRITICAL FIXES:
-- 1. Validates input parameters before processing
-- 2. Checks sqlpage.exec() exit code (0 = success, non-zero = error)
-- 3. Returns proper JSON response with error details
-- 4. Uses SET variables to suppress HTML rendering of exec output

-- Resolve destination once into a variable
SET _dest = COALESCE(
    (SELECT destination_path FROM path_settings 
     WHERE setting_key = 'markdown_destination' LIMIT 1),
    sqlpage.environment_variable('MARKDOWN_DESTINATION_PATH'),
    'test-artifacts'
);

-- VALIDATION: Check if required parameters are present
-- If filename or content is NULL, return error immediately
SELECT 'json' AS component,
    json_object(
        'success', false,
        'error', 'Missing required parameter: ' || 
                 CASE 
                    WHEN :filename IS NULL THEN 'filename'
                    WHEN :content IS NULL THEN 'content'
                    ELSE 'unknown'
                 END,
        'details', 'Both filename and content are required to save markdown'
    ) AS value
WHERE :filename IS NULL OR :content IS NULL;

-- Create the folder — absorb into SET variable to suppress HTML rendering
SET _mkdir_result = sqlpage.exec(
    'mkdir', '-p',
    '../' || $_dest
);

-- Write the markdown file — capture exit code to verify success
-- NOTE: sqlpage.exec() returns the exit code, not the output
-- Exit code 0 = success, non-zero = error
SET _exec_result = sqlpage.exec(
    'sh',
    'scripts/write_markdown.sh',
    $_dest,
    :filename,
    :content
);

-- Return clean JSON — the ONLY thing rendered to the HTTP response body
-- Check exit code to determine success or failure
SELECT 'json' AS component,
    CASE 
        WHEN _exec_result = 0 THEN
            -- Script succeeded (exit code 0)
            json_object(
                'success', true,
                'folder', $_dest,
                'filename', :filename,
                'message', 'Markdown file saved successfully',
                'path', $_dest || '/' || :filename
            )
        ELSE
            -- Script failed (non-zero exit code)
            json_object(
                'success', false,
                'error', 'Script execution failed',
                'exit_code', _exec_result,
                'folder', $_dest,
                'filename', :filename,
                'details', 'Check server logs for details. The script may not exist or returned an error.'
            )
    END AS value;