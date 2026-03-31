-- /pages/get_markdown_destination.sql
-- API endpoint for generator.js to fetch the current markdown destination path
-- Called on page load to ensure generator uses latest setting

SELECT 'json' AS component,
    json_object(
        'success', true,
        'destination', COALESCE(
            (SELECT destination_path FROM path_settings 
             WHERE setting_key = 'markdown_destination' LIMIT 1),
            'test-artifacts'
        ),
        'message', 'Markdown destination retrieved successfully'
    ) AS value;