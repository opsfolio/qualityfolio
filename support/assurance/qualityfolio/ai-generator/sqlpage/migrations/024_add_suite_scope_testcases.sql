-- Migration 024: Add scope and test_cases_summary to suites table

-- Add scope column (for detailed suite scope description)
ALTER TABLE suites ADD COLUMN scope TEXT;

-- Add test_cases_summary column (for grouped test cases listing)
ALTER TABLE suites ADD COLUMN test_cases_summary TEXT;
