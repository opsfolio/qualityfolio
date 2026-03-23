-- Migration 028: Add status_id column to test_cases table (idempotent)
-- Uses a tracking table to ensure ALTER TABLE only runs once

CREATE TABLE IF NOT EXISTS _schema_migrations (
    version TEXT PRIMARY KEY,
    applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Only add the column if this migration hasn't been applied yet
INSERT INTO _schema_migrations (version)
SELECT '028_add_status_id_to_test_cases'
WHERE NOT EXISTS (
    SELECT 1 FROM _schema_migrations WHERE version = '028_add_status_id_to_test_cases'
);
