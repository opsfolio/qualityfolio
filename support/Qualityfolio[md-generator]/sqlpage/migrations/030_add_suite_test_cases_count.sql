-- Migration 030: Add test_cases_count column to suites table
-- Stores the intended AI-generated test case count when a suite is manually created
ALTER TABLE suites ADD COLUMN test_cases_count INTEGER;
