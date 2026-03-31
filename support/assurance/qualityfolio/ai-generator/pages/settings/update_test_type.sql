-- Update test type handler
SET _name = COALESCE(:name, $name);
SET _description = COALESCE(:description, $description);
SET _id = CAST(REPLACE(COALESCE(:edit_id, $edit_id, '0'), ',', '') AS INTEGER);

UPDATE test_types 
SET name = $_name,
    description = $_description
WHERE id = $_id;

-- Redirect back to settings with test_types tab active
SELECT 'redirect' AS component,
       '/settings.sql?tab=test_types&success=Test+type+updated+successfully' AS link;
