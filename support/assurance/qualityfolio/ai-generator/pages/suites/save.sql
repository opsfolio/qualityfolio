-- Save a new Suite and generate test cases

-- 1. Insert into suites
-- Ensure debug_log table exists (Immediate fix)
CREATE TABLE IF NOT EXISTS debug_log (
    id INTEGER PRIMARY KEY,
    content TEXT,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

-- Ensure suite_configs table exists (safe - CREATE TABLE IF NOT EXISTS)
CREATE TABLE IF NOT EXISTS suite_configs (
    suite_id INTEGER PRIMARY KEY REFERENCES suites(id) ON DELETE CASCADE,
    test_cases_count INTEGER
);

INSERT INTO suites (project_id, plan_id, name, external_id, suite_date, created_by_id, description, scope)
SELECT 
    :project_id,
    NULLIF(:plan_id, ''),
    :suite_name,
    :suite_id,
    :suite_date,
    :suite_created_by,
    'Manually created suite',
    :scope
WHERE :project_id IS NOT NULL AND :suite_name IS NOT NULL;

SET suite_id = LAST_INSERT_ROWID();

-- Store the test case count for this suite (if provided)
INSERT OR REPLACE INTO suite_configs (suite_id, test_cases_count)
SELECT $suite_id, CAST(:test_cases_count AS INTEGER)
WHERE $suite_id > 0 AND CAST(:test_cases_count AS INTEGER) > 0;

-- 2. Redirect to AI Generation
-- This uses the unified generate_test_cases.sql which contains the descriptive prompts
SELECT 'redirect' AS component,
       'generate_test_cases.sql?project_id=' || :project_id || 
       '&suite_id=' || $suite_id || 
       '&count=' || :test_cases_count AS link
WHERE $suite_id > 0;
