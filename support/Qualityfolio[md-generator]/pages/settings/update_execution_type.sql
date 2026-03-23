-- Update execution type handler
SET _name = COALESCE(:name, $name);
SET _id = CAST(REPLACE(COALESCE(:edit_id, $edit_id, '0'), ',', '') AS INTEGER);

UPDATE execution_types 
SET name = $_name
WHERE id = $_id;

-- Redirect back to settings with execution_types tab active
SELECT 'redirect' AS component,
       '/settings.sql?tab=execution_types&success=Execution+type+updated+successfully' AS link;
