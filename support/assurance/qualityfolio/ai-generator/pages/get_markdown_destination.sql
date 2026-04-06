-- /pages/get_markdown_destination.sql
-- API endpoint for generator.js to fetch the current markdown destination path
-- Called on page load to ensure generator uses latest setting
-- Always returns valid JSON, even on error

SELECT 'json' AS component,
    json_object(
        'success', true,
        'destination', COALESCE(
            (SELECT destination_path FROM path_settings 
             WHERE setting_key = 'markdown_destination' LIMIT 1),
            sqlpage.environment_variable('MARKDOWN_DESTINATION_PATH'),
            'test-artifacts'
        ),
        'message', 'Markdown destination retrieved successfully'
    ) AS value;