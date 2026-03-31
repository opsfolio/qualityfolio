-- Update test case status handler
SET _name = COALESCE(:name, $name);
SET _id = CAST(REPLACE(COALESCE(:edit_id, $edit_id, '0'), ',', '') AS INTEGER);

UPDATE test_case_statuses
SET name = $_name
WHERE id = $_id;

-- Redirect back to settings
SELECT 'redirect' AS component,
       '/settings.sql?tab=test_case_statuses&success=Status+updated+successfully' AS link;
