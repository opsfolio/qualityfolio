-- Migration 011: Add created_by_id to plans table
ALTER TABLE plans ADD COLUMN created_by_id INTEGER REFERENCES team_members(id);

-- Index for creator lookup
CREATE INDEX IF NOT EXISTS idx_plans_creator ON plans(created_by_id);
