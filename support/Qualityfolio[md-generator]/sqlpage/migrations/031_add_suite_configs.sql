-- Migration 031: Create suite_configs table for per-suite test case count
-- A separate table is used for safe, idempotent storage of suite-level config
CREATE TABLE IF NOT EXISTS suite_configs (
    suite_id INTEGER PRIMARY KEY REFERENCES suites(id) ON DELETE CASCADE,
    test_cases_count INTEGER
);
