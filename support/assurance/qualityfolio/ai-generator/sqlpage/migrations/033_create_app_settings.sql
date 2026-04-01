-- Migration 033: Create app_settings table for global key-value config
CREATE TABLE IF NOT EXISTS app_settings (
    key   TEXT PRIMARY KEY,
    value TEXT NOT NULL DEFAULT ''
);

-- Seed default TC ID format (no REQ prefix by default)
INSERT OR IGNORE INTO app_settings (key, value) VALUES ('tc_id_format', 'TC-{NUM}');

-- Update existing rows that still have the old default to use the new cleaner default
UPDATE app_settings SET value = 'TC-{NUM}' WHERE key = 'tc_id_format' AND value = '{REQ}-TC-{NUM}';
