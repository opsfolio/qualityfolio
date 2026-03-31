-- /pages/settings/update_markdown_path.sql
-- Updates an existing markdown path configuration in path_settings (key-value style)

-- Step 1: If this entry is being set as default, strip default flag from all other markdown paths
UPDATE path_settings
SET destination_path = SUBSTR(destination_path, 9)   -- strip leading 'default|'
WHERE setting_key LIKE 'markdown_path_%'
  AND destination_path LIKE 'default|%'
  AND setting_key != :edit_key
  AND :is_default = 'on';

-- Step 2: Update the target row by its setting_key
UPDATE path_settings
SET destination_path = CASE WHEN :is_default = 'on'
                            THEN 'default|' || :path_type || '|' || :destination_path
                            ELSE :path_type || '|' || :destination_path
                       END,
    description      = :path_name,
    updated_at       = CURRENT_TIMESTAMP
WHERE setting_key = :edit_key;

-- Redirect back to the Markdown Paths tab
SELECT 'redirect' AS component,
       'settings.sql?tab=markdown_paths' AS link;