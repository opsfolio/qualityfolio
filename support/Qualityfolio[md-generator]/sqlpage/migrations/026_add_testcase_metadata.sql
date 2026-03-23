-- Migration 026: Add test case metadata fields

-- Add priority column
ALTER TABLE test_cases ADD COLUMN priority TEXT;

-- Add tags column (stored as JSON array or comma-separated)
ALTER TABLE test_cases ADD COLUMN tags TEXT;

-- Add preconditions column (stored as markdown checklist)
ALTER TABLE test_cases ADD COLUMN preconditions TEXT;

-- Add steps column (stored as markdown checklist)
ALTER TABLE test_cases ADD COLUMN steps TEXT;

-- Add expected_results column (stored as markdown checklist)
ALTER TABLE test_cases ADD COLUMN expected_results TEXT;
