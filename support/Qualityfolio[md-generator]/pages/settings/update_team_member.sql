-- Update team member handler
SET _full_name = COALESCE(:full_name, $full_name);
SET _designation = COALESCE(:designation, $designation);
SET _id = CAST(REPLACE(COALESCE(:edit_id, $edit_id, '0'), ',', '') AS INTEGER);

UPDATE team_members 
SET full_name = $_full_name,
    designation = $_designation
WHERE id = $_id;

-- Redirect back to settings
SELECT 'redirect' AS component,
       '/settings.sql?tab=team_members&success=Team+member+updated+successfully' AS link;
