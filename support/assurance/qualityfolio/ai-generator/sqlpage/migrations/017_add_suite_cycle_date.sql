-- Migration 017: Add cycle_date to suites table
ALTER TABLE suites ADD COLUMN cycle_date DATE;

-- Index for cycle date lookup
CREATE INDEX IF NOT EXISTS idx_suites_cycle_date ON suites(cycle_date);
