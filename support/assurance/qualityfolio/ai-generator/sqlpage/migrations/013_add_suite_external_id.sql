-- Migration 013: Add external_id to suites table
ALTER TABLE suites ADD COLUMN external_id TEXT;

-- Index for suite ID lookup
CREATE INDEX IF NOT EXISTS idx_suites_external_id ON suites(external_id);
