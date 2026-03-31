-- Update tag handler
SET _name = COALESCE(:name, $name);
SET _id = CAST(REPLACE(COALESCE(:edit_id, $edit_id, '0'), ',', '') AS INTEGER);

UPDATE tags 
SET name = $_name
WHERE id = $_id;

-- Redirect back to settings with tags tab active
SELECT 'redirect' AS component,
       '/settings.sql?tab=tags&success=Tag+updated+successfully' AS link;
