-- Migration 014: Add suite_date to suites table
ALTER TABLE suites ADD COLUMN suite_date DATE;

-- Index for suite date lookup
CREATE INDEX IF NOT EXISTS idx_suites_date ON suites(suite_date);
