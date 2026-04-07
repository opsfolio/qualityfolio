-- Save test case status handler
INSERT OR IGNORE INTO test_case_statuses (name)
VALUES (:name);

-- Redirect back to settings, with appropriate message
SELECT 'redirect' AS component,
       CASE
         WHEN changes() = 0
           THEN '/settings.sql?tab=test_case_statuses&error=Status+already+exists'
         ELSE '/settings.sql?tab=test_case_statuses&success=Status+added+successfully'
       END AS link;