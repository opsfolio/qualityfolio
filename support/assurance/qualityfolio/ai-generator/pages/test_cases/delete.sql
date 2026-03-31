-- Action to delete a test case
DELETE FROM test_cases WHERE id = $id;

-- Redirect back to the list
SELECT 'redirect' AS component, 
       'test_cases.sql?project_id=' || $project_id || '&suite_id=' || COALESCE($suite_id, '') AS link;
