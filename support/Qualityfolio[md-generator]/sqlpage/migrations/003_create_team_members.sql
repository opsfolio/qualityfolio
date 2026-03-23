-- Migration 003: Create team members table

-- Team members table
CREATE TABLE IF NOT EXISTS team_members (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    full_name TEXT NOT NULL,
    designation TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create index on full_name for faster lookups
CREATE INDEX IF NOT EXISTS idx_team_members_name ON team_members(full_name);
