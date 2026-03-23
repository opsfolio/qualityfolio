-- Save test case status handler
INSERT INTO test_case_statuses (name)
VALUES (:name);

-- Redirect back to settings
SELECT 'redirect' AS component,
       '/settings.sql?tab=test_case_statuses&success=Status+added+successfully' AS link;
