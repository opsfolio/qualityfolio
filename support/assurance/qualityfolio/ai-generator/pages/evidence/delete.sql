-- Delete Evidence
INSERT INTO debug_log (content) VALUES ('Attempting to delete evidence ID: ' || COALESCE($id, 'NULL') || ' for Test Case: ' || COALESCE($test_case_id, 'NULL'));
DELETE FROM evidence WHERE id = $id;

SELECT 'redirect' AS component, 
       'evidence.sql?test_case_id=' || COALESCE($test_case_id, '') || '&project_id=' || COALESCE($project_id, '') || '&suite_id=' || COALESCE($suite_id, '') AS link;
