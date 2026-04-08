-- Migration 003: Create team members table (UPDATED with duplicate prevention)

-- Team members table
CREATE TABLE IF NOT EXISTS team_members (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    full_name TEXT NOT NULL UNIQUE,
    designation TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create index on full_name for faster lookups and duplicate detection
CREATE INDEX IF NOT EXISTS idx_team_members_name ON team_members(full_name);

-- Trigger to auto-update the updated_at timestamp when a record is modified
CREATE TRIGGER IF NOT EXISTS team_members_update_timestamp
AFTER UPDATE ON team_members
FOR EACH ROW
BEGIN
  UPDATE team_members SET updated_at = CURRENT_TIMESTAMP WHERE id = NEW.id;
END;