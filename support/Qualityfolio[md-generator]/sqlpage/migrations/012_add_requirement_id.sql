-- Migration 012: Add requirement_id to test_cases table
ALTER TABLE test_cases ADD COLUMN requirement_id TEXT;

-- Index for requirement ID lookup
CREATE INDEX IF NOT EXISTS idx_test_cases_requirement_id ON test_cases(requirement_id);
