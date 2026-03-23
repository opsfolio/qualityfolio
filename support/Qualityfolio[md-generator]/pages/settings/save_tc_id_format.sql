-- Save/update the ID format settings
INSERT INTO app_settings (key, value)
VALUES 
    ('tc_id_format', COALESCE(NULLIF(TRIM(:tc_id_format), ''), 'TC-{NUM}')),
    ('plan_id_format', COALESCE(NULLIF(TRIM(:plan_id_format), ''), 'PL-{NUM}')),
    ('suite_id_format', COALESCE(NULLIF(TRIM(:suite_id_format), ''), 'ST-{NUM}')),
    ('req_id_format', COALESCE(NULLIF(TRIM(:req_id_format), ''), 'RQ-{NUM}'))
ON CONFLICT(key) DO UPDATE SET value = excluded.value;

SELECT 'redirect' AS component,
       '/settings.sql?tab=id_formats&success=ID+Formats+saved+successfully' AS link;
