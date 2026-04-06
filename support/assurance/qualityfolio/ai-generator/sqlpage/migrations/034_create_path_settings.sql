-- Migration 034: Create path_settings table for managing file destination paths

-- Path settings table for storing configurable paths
CREATE TABLE IF NOT EXISTS path_settings (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    setting_key TEXT NOT NULL UNIQUE,
    destination_path TEXT NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create index on setting_key for faster lookups
CREATE INDEX IF NOT EXISTS idx_path_settings_key ON path_settings(setting_key);

-- Insert default path settings
INSERT OR IGNORE INTO path_settings (setting_key, destination_path, description) VALUES
    ('markdown_destination', 'test-artifacts', 'Default destination folder for saved markdown files'),
    ('evidence_path', 'evidence', 'Path for storing test evidence files'),
    ('exports_path', 'exports', 'Path for exporting reports and data'),
    ('imports_path', 'imports', 'Path for importing data files');

-- Create trigger to auto-update updated_at timestamp
CREATE TRIGGER IF NOT EXISTS path_settings_update_timestamp 
AFTER UPDATE ON path_settings
BEGIN
  UPDATE path_settings SET updated_at = CURRENT_TIMESTAMP WHERE id = NEW.id;
END;
