-- Migration 016: Add cycle to suites table
ALTER TABLE suites ADD COLUMN cycle TEXT;

-- Index for cycle lookup
CREATE INDEX IF NOT EXISTS idx_suites_cycle ON suites(cycle);
