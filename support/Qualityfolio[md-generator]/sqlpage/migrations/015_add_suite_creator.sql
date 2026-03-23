-- Migration 015: Add created_by_id to suites table
ALTER TABLE suites ADD COLUMN created_by_id INTEGER REFERENCES team_members(id);

-- Index for creator lookup
CREATE INDEX IF NOT EXISTS idx_suites_creator ON suites(created_by_id);
