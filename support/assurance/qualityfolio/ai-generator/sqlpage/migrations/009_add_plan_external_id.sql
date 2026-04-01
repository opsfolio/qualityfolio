-- Migration 009: Add external_id to plans table
ALTER TABLE plans ADD COLUMN external_id TEXT;

-- Index for plan ID lookup
CREATE INDEX IF NOT EXISTS idx_plans_external_id ON plans(external_id);
