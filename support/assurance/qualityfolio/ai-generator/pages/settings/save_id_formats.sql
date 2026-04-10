-- Save/update the ID format settings
-- Form fields → DB keys → settings.sql SET variables all aligned:
--   tc_id_format  → 'tc_id_format'  → _tc_id_format
--   scn_id_format → 'scn_id_format' → _scn_id_format
--   req_id_format → 'req_id_format' → _req_id_format
--   pl_id_format  → 'pl_id_format'  → _pl_id_format
--   st_id_format  → 'st_id_format'  → _st_id_format

INSERT INTO app_settings (key, value)
VALUES
    ('tc_id_format',  COALESCE(NULLIF(TRIM(:tc_id_format),  ''), 'TC-{PRJ}-{NUM}')),
    ('scn_id_format', COALESCE(NULLIF(TRIM(:scn_id_format), ''), 'SCN-{NUM}')),
    ('req_id_format', COALESCE(NULLIF(TRIM(:req_id_format), ''), 'RQ-{NUM}')),
    ('pl_id_format',  COALESCE(NULLIF(TRIM(:pl_id_format),  ''), 'PL-{NUM}')),
    ('st_id_format',  COALESCE(NULLIF(TRIM(:st_id_format),  ''), 'ST-{NUM}'))
ON CONFLICT(key) DO UPDATE SET value = excluded.value;

SELECT 'redirect' AS component,
       '/settings.sql?tab=id_formats&success=ID+Formats+saved+successfully' AS link;